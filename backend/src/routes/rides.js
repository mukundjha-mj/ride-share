const express = require('express');
const Ride = require('../models/Ride');
const JoinRequest = require('../models/JoinRequest');
const auth = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// All ride routes require authentication
router.use(auth);

// POST /rides - Create a new ride
router.post('/', validate('createRide'), async (req, res) => {
    try {
        const { from, to, timeStart, timeEnd, seats } = req.body;

        const startDate = new Date(timeStart);
        const endDate = new Date(timeEnd);

        // Validate times (additional check)
        if (startDate < new Date()) {
            return res.status(400).json({
                success: false,
                message: 'Start time cannot be in the past'
            });
        }

        const ride = await Ride.create({
            ownerId: req.userId,
            from,
            to,
            timeStart: startDate,
            timeEnd: endDate,
            seats: seats || 1
        });

        // Populate owner details
        await ride.populate('owner');

        // 🔌 Emit new ride event
        const { socketEvents } = require('../services/websocketClient');
        socketEvents.newRide(ride);

        res.status(201).json({
            success: true,
            message: 'Ride created successfully',
            data: { ride }
        });
    } catch (error) {
        console.error('Create ride error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error creating ride'
        });
    }
});

// GET /rides - List open rides (not my own, status=open, timeEnd > now)
router.get('/', async (req, res) => {
    try {
        const rides = await Ride.find({
            status: 'open',
            timeEnd: { $gt: new Date() },
            ownerId: { $ne: req.userId }
        })
            .populate('owner')
            .sort({ timeStart: 1 });

        res.json({
            success: true,
            data: { rides }
        });
    } catch (error) {
        console.error('List rides error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching rides'
        });
    }
});

// GET /rides/my - Get my posted rides
router.get('/my', async (req, res) => {
    try {
        const rides = await Ride.find({ ownerId: req.userId })
            .sort({ createdAt: -1 });

        // Get pending request counts for each ride
        const ridesWithCounts = await Promise.all(
            rides.map(async (ride) => {
                const pendingCount = await JoinRequest.countDocuments({
                    rideId: ride._id,
                    status: 'pending'
                });
                return {
                    ...ride.toJSON(),
                    pendingRequestCount: pendingCount
                };
            })
        );

        res.json({
            success: true,
            data: { rides: ridesWithCounts }
        });
    } catch (error) {
        console.error('Get my rides error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching your rides'
        });
    }
});

// GET /rides/:id - Get single ride details
router.get('/:id', async (req, res) => {
    try {
        const ride = await Ride.findById(req.params.id).populate('owner');

        if (!ride) {
            return res.status(404).json({
                success: false,
                message: 'Ride not found'
            });
        }

        // Check if current user has a join request for this ride
        const myRequest = await JoinRequest.findOne({
            rideId: ride._id,
            requesterId: req.userId
        });

        res.json({
            success: true,
            data: {
                ride,
                myRequest,
                isOwner: ride.ownerId.toString() === req.userId.toString()
            }
        });
    } catch (error) {
        console.error('Get ride error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error fetching ride'
        });
    }
});

// DELETE /rides/:id - Cancel a ride (owner only)
router.delete('/:id', async (req, res) => {
    try {
        const ride = await Ride.findById(req.params.id);

        if (!ride) {
            return res.status(404).json({
                success: false,
                message: 'Ride not found'
            });
        }

        if (ride.ownerId.toString() !== req.userId.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Only the ride owner can cancel this ride'
            });
        }

        if (ride.status === 'filled') {
            return res.status(400).json({
                success: false,
                message: 'Cannot cancel a filled ride'
            });
        }

        ride.status = 'cancelled';
        await ride.save();

        // 🔌 Emit ride cancelled event
        const { socketEvents } = require('../services/websocketClient');
        socketEvents.rideCancelled(ride._id);

        res.json({
            success: true,
            message: 'Ride cancelled successfully',
            data: { ride }
        });
    } catch (error) {
        console.error('Cancel ride error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error cancelling ride'
        });
    }
});

module.exports = router;
