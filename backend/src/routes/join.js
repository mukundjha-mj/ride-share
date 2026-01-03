const express = require('express');
const mongoose = require('mongoose');
const Ride = require('../models/Ride');
const JoinRequest = require('../models/JoinRequest');
const ChatMessage = require('../models/ChatMessage');
const auth = require('../middleware/auth');
const { joinLimiter } = require('../middleware/rateLimiter');
const { socketEvents } = require('../socket');

const router = express.Router();

router.use(auth);

// POST /rides/:rideId/join - Request to join a ride
router.post('/rides/:rideId/join', joinLimiter, async (req, res) => {
    try {
        const { rideId } = req.params;
        const ride = await Ride.findById(rideId);

        if (!ride) {
            return res.status(404).json({ success: false, message: 'Ride not found' });
        }

        if (ride.ownerId.toString() === req.userId.toString()) {
            return res.status(400).json({ success: false, message: 'Cannot join your own ride' });
        }

        if (ride.status !== 'open') {
            return res.status(400).json({ success: false, message: 'This ride is no longer available' });
        }

        if (new Date() > ride.timeEnd) {
            return res.status(400).json({ success: false, message: 'This ride has expired' });
        }

        const existingRequest = await JoinRequest.findOne({ rideId, requesterId: req.userId });
        if (existingRequest) {
            return res.status(400).json({
                success: false,
                message: 'You have already requested to join this ride',
                data: { joinRequest: existingRequest }
            });
        }

        const joinRequest = await JoinRequest.create({ rideId, requesterId: req.userId });
        await joinRequest.populate('requester');

        // 🔌 Notify ride owner of new request
        socketEvents.newJoinRequest(rideId, joinRequest);

        res.status(201).json({
            success: true,
            message: 'Join request sent successfully',
            data: { joinRequest }
        });
    } catch (error) {
        console.error('Join request error:', error);
        res.status(500).json({ success: false, message: 'Server error creating join request' });
    }
});

// GET /rides/:rideId/requests - Get all join requests for a ride (owner only)
router.get('/rides/:rideId/requests', async (req, res) => {
    try {
        const { rideId } = req.params;
        const ride = await Ride.findById(rideId);

        if (!ride) {
            return res.status(404).json({ success: false, message: 'Ride not found' });
        }

        if (ride.ownerId.toString() !== req.userId.toString()) {
            return res.status(403).json({ success: false, message: 'Only the ride owner can view all requests' });
        }

        const requests = await JoinRequest.find({ rideId }).populate('requester').sort({ createdAt: -1 });
        res.json({ success: true, data: { requests } });
    } catch (error) {
        console.error('Get requests error:', error);
        res.status(500).json({ success: false, message: 'Server error fetching requests' });
    }
});

// POST /join/:joinId/accept - Accept a join request (CRITICAL LOGIC)
router.post('/join/:joinId/accept', async (req, res) => {
    const session = await mongoose.startSession();

    try {
        session.startTransaction();
        const { joinId } = req.params;

        const joinRequest = await JoinRequest.findById(joinId).session(session);
        if (!joinRequest) {
            await session.abortTransaction();
            return res.status(404).json({ success: false, message: 'Join request not found' });
        }

        const ride = await Ride.findById(joinRequest.rideId).session(session);
        if (!ride) {
            await session.abortTransaction();
            return res.status(404).json({ success: false, message: 'Ride not found' });
        }

        if (ride.ownerId.toString() !== req.userId.toString()) {
            await session.abortTransaction();
            return res.status(403).json({ success: false, message: 'Only the ride owner can accept requests' });
        }

        if (ride.status !== 'open') {
            await session.abortTransaction();
            return res.status(400).json({ success: false, message: 'This ride is no longer open' });
        }

        if (joinRequest.status !== 'pending') {
            await session.abortTransaction();
            return res.status(400).json({ success: false, message: 'This request has already been processed' });
        }

        // ========== CRITICAL ACCEPT LOGIC ==========

        // 1. Accept this request
        joinRequest.status = 'accepted';
        await joinRequest.save({ session });

        // 2. System message for accepted
        const acceptedMessage = await ChatMessage.create([{
            joinRequestId: joinRequest._id,
            senderId: req.userId,
            message: '🎉 Ride confirmed! You can now coordinate your trip.',
            isSystemMessage: true
        }], { session });

        // 3. Reject others
        const otherRequests = await JoinRequest.find({
            rideId: ride._id,
            _id: { $ne: joinRequest._id },
            status: 'pending'
        }).session(session);

        for (const other of otherRequests) {
            other.status = 'rejected';
            await other.save({ session });

            await ChatMessage.create([{
                joinRequestId: other._id,
                senderId: req.userId,
                message: 'This ride has been filled. Thanks for your interest!',
                isSystemMessage: true
            }], { session });
        }

        // 4. Mark ride as filled
        ride.status = 'filled';
        await ride.save({ session });

        await session.commitTransaction();
        await joinRequest.populate('requester');

        // 🔌 Emit real-time events
        socketEvents.requestAccepted(joinRequest.requesterId.toString(), { joinRequest, ride });
        socketEvents.newMessage(joinRequest._id.toString(), acceptedMessage[0]);

        for (const other of otherRequests) {
            socketEvents.requestRejected(other.requesterId.toString(), { rideId: ride._id });
        }

        socketEvents.rideFilled(ride._id.toString());

        res.json({
            success: true,
            message: 'Request accepted successfully',
            data: { acceptedRequest: joinRequest, rejectedCount: otherRequests.length }
        });
    } catch (error) {
        await session.abortTransaction();
        console.error('Accept request error:', error);
        res.status(500).json({ success: false, message: 'Server error accepting request' });
    } finally {
        session.endSession();
    }
});

// GET /join/my - Get all my join requests
router.get('/join/my', async (req, res) => {
    try {
        const requests = await JoinRequest.find({ requesterId: req.userId })
            .populate({ path: 'rideId', populate: { path: 'owner' } })
            .sort({ createdAt: -1 });
        res.json({ success: true, data: { requests } });
    } catch (error) {
        console.error('Get my requests error:', error);
        res.status(500).json({ success: false, message: 'Server error fetching your requests' });
    }
});

module.exports = router;
