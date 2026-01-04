const express = require('express');
const JoinRequest = require('../models/JoinRequest');
const ChatMessage = require('../models/ChatMessage');
const Ride = require('../models/Ride');
const auth = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { chatLimiter } = require('../middleware/rateLimiter');
const { socketEvents } = require('../services/websocketClient');

const router = express.Router();

// All chat routes require authentication
router.use(auth);

// GET /join/:joinId/messages - Get all messages for a chat
router.get('/join/:joinId/messages', async (req, res) => {
    try {
        const { joinId } = req.params;

        const joinRequest = await JoinRequest.findById(joinId).populate('requester');
        if (!joinRequest) {
            return res.status(404).json({ success: false, message: 'Chat not found' });
        }

        const ride = await Ride.findById(joinRequest.rideId);
        if (!ride) {
            return res.status(404).json({ success: false, message: 'Ride not found' });
        }

        const isOwner = ride.ownerId.toString() === req.userId.toString();
        const isRequester = joinRequest.requesterId.toString() === req.userId.toString();

        if (!isOwner && !isRequester) {
            return res.status(403).json({ success: false, message: 'You do not have access to this chat' });
        }

        const messages = await ChatMessage.find({ joinRequestId: joinId }).sort({ createdAt: 1 });

        // Mark as read for this user
        const now = new Date();
        if (isOwner) {
            joinRequest.lastReadOwner = now;
        } else {
            joinRequest.lastReadRequester = now;
        }
        await joinRequest.save();

        // 🔌 Emit messages read event
        socketEvents.messagesRead(joinId, req.userId, now);

        res.json({
            success: true,
            data: {
                messages,
                joinRequest,
                isOwner,
                canSendMessage: joinRequest.status === 'pending' || joinRequest.status === 'accepted'
            }
        });
    } catch (error) {
        console.error('Get messages error:', error);
        res.status(500).json({ success: false, message: 'Server error fetching messages' });
    }
});

// POST /join/:joinId/read - Mark messages as read
router.post('/join/:joinId/read', chatLimiter, async (req, res) => {
    try {
        const { joinId } = req.params;

        const joinRequest = await JoinRequest.findById(joinId);
        if (!joinRequest) {
            return res.status(404).json({ success: false, message: 'Chat not found' });
        }

        const isOwner = joinRequest.rideId && (await Ride.findById(joinRequest.rideId))?.ownerId.toString() === req.userId.toString();

        // Populate ride if needed to be sure about owner, but simpler:
        // We can just check joinRequest fields if populated, but they aren't.
        // Re-fetching logic similar to GET messages to determine owner/requester

        // Actually, let's just use the existing logic or simpler:
        // JoinRequest has requesterId. If req.userId == requesterId -> Requester.
        // Else -> Owner (implicit, but should verify).

        const isRequester = joinRequest.requesterId.toString() === req.userId.toString();

        // We need to know if it's owner. 
        // Best to look up Ride.
        const ride = await Ride.findById(joinRequest.rideId);
        if (!ride) return res.status(404).json({ message: 'Ride not found' });

        const isRideOwner = ride.ownerId.toString() === req.userId.toString();

        if (!isRideOwner && !isRequester) {
            return res.status(403).json({ success: false, message: 'Access denied' });
        }

        const now = new Date();
        if (isRideOwner) {
            joinRequest.lastReadOwner = now;
        } else {
            joinRequest.lastReadRequester = now;
        }
        await joinRequest.save();

        // 🔌 Emit messages read event
        socketEvents.messagesRead(joinId, req.userId, now);

        res.json({ success: true });
    } catch (error) {
        console.error('Mark read error:', error);
        res.status(500).json({ success: false });
    }
});

// POST /join/:joinId/messages - Send a message
router.post('/join/:joinId/messages', chatLimiter, validate('sendMessage'), async (req, res) => {
    try {
        const { joinId } = req.params;
        const { message } = req.body;

        const joinRequest = await JoinRequest.findById(joinId);
        if (!joinRequest) {
            return res.status(404).json({ success: false, message: 'Chat not found' });
        }

        const ride = await Ride.findById(joinRequest.rideId);
        if (!ride) {
            return res.status(404).json({ success: false, message: 'Ride not found' });
        }

        const isOwner = ride.ownerId.toString() === req.userId.toString();
        const isRequester = joinRequest.requesterId.toString() === req.userId.toString();

        if (!isOwner && !isRequester) {
            return res.status(403).json({ success: false, message: 'You do not have access to this chat' });
        }

        if (joinRequest.status === 'rejected') {
            return res.status(400).json({ success: false, message: 'This chat has been closed' });
        }

        // Create message
        const chatMessage = await ChatMessage.create({
            joinRequestId: joinId,
            senderId: req.userId,
            message: message.trim()
        });

        // 🔌 Emit real-time event
        socketEvents.newMessage(joinId, chatMessage);

        res.status(201).json({
            success: true,
            message: 'Message sent',
            data: { chatMessage }
        });
    } catch (error) {
        console.error('Send message error:', error);
        res.status(500).json({ success: false, message: 'Server error sending message' });
    }
});

module.exports = router;

// PUT /join/:joinId/messages/:messageId - Edit a message
router.put('/join/:joinId/messages/:messageId', chatLimiter, validate('sendMessage'), async (req, res) => {
    try {
        const { joinId, messageId } = req.params;
        const { message } = req.body;

        const chatMessage = await ChatMessage.findById(messageId);
        if (!chatMessage) {
            return res.status(404).json({ success: false, message: 'Message not found' });
        }

        if (chatMessage.senderId.toString() !== req.userId.toString()) {
            return res.status(403).json({ success: false, message: 'You can only edit your own messages' });
        }

        if (chatMessage.joinRequestId.toString() !== joinId) {
            return res.status(400).json({ success: false, message: 'Message does not belong to this chat' });
        }

        // Update message
        chatMessage.message = message.trim();
        chatMessage.isEdited = true;
        await chatMessage.save();


        // 🔌 Emit real-time event
        socketEvents.messageEdited(joinId, chatMessage);

        res.json({
            success: true,
            message: 'Message updated',
            data: { chatMessage }
        });
    } catch (error) {
        console.error('Edit message error:', error);
        res.status(500).json({ success: false, message: 'Server error editing message' });
    }
});

// DELETE /join/:joinId/messages/:messageId - Delete a message
router.delete('/join/:joinId/messages/:messageId', chatLimiter, async (req, res) => {
    try {
        const { joinId, messageId } = req.params;

        const chatMessage = await ChatMessage.findById(messageId);
        if (!chatMessage) {
            return res.status(404).json({ success: false, message: 'Message not found' });
        }

        if (chatMessage.senderId.toString() !== req.userId.toString()) {
            return res.status(403).json({ success: false, message: 'You can only delete your own messages' });
        }

        if (chatMessage.joinRequestId.toString() !== joinId) {
            return res.status(400).json({ success: false, message: 'Message does not belong to this chat' });
        }

        // Delete message
        await ChatMessage.deleteOne({ _id: messageId });

        // 🔌 Emit real-time event
        socketEvents.messageDeleted(joinId, messageId);

        res.json({
            success: true,
            message: 'Message deleted'
        });
    } catch (error) {
        console.error('Delete message error:', error);
        res.status(500).json({ success: false, message: 'Server error deleting message' });
    }
});
