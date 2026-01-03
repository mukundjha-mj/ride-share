const Ride = require('../models/Ride');
const JoinRequest = require('../models/JoinRequest');
const ChatMessage = require('../models/ChatMessage');

/**
 * Auto-expire rides that have passed their timeEnd
 * This runs periodically to clean up stale rides
 */
const expireOldRides = async () => {
    try {
        const now = new Date();

        // Find all open rides where timeEnd has passed
        const expiredRides = await Ride.find({
            status: 'open',
            timeEnd: { $lt: now }
        });

        for (const ride of expiredRides) {
            // Mark ride as cancelled
            ride.status = 'cancelled';
            await ride.save();

            // Reject all pending requests with a system message
            const pendingRequests = await JoinRequest.find({
                rideId: ride._id,
                status: 'pending'
            });

            for (const request of pendingRequests) {
                request.status = 'rejected';
                await request.save();

                // Add system message
                await ChatMessage.create({
                    joinRequestId: request._id,
                    senderId: ride.ownerId,
                    message: 'This ride has expired.',
                    isSystemMessage: true
                });
            }
        }

        if (expiredRides.length > 0) {
            console.log(`🧹 Expired ${expiredRides.length} ride(s)`);
        }
    } catch (error) {
        console.error('Error expiring rides:', error);
    }
};

/**
 * Start the cleanup job - runs every 5 minutes
 */
const startCleanupJob = () => {
    // Run immediately on startup
    expireOldRides();

    // Then run every 5 minutes
    setInterval(expireOldRides, 5 * 60 * 1000);

    console.log('🔄 Auto-expire job started (runs every 5 minutes)');
};

module.exports = { startCleanupJob, expireOldRides };
