const express = require('express');
const JoinRequest = require('../models/JoinRequest');
const ChatMessage = require('../models/ChatMessage');
const Ride = require('../models/Ride');
const auth = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { chatLimiter } = require('../middleware/rateLimiter');
const { socketEvents } = require('../socket');

const router = express.Router();

// All chat routes require authentication
router.use(auth);

// GET /join/:joinId/messages - Get all messages for a chat
router.get('/join/:joinId/messages', async (req, res) => {
    try {
        const { joinId } = req.params;

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

        const messages = await ChatMessage.find({ joinRequestId: joinId }).sort({ createdAt: 1 });

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
