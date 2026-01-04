const mongoose = require('mongoose');

const joinRequestSchema = new mongoose.Schema({
    rideId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Ride',
        required: true
    },
    requesterId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected'],
        default: 'pending'
    },
    // Track when each user last read messages
    lastReadOwner: {
        type: Date,
        default: Date.now
    },
    lastReadRequester: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// Compound index to prevent duplicate join requests
joinRequestSchema.index({ rideId: 1, requesterId: 1 }, { unique: true });

// Index for querying requests by ride
joinRequestSchema.index({ rideId: 1, status: 1 });

// Virtual to populate requester details
joinRequestSchema.virtual('requester', {
    ref: 'User',
    localField: 'requesterId',
    foreignField: '_id',
    justOne: true
});

joinRequestSchema.set('toJSON', { virtuals: true });
joinRequestSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('JoinRequest', joinRequestSchema);
