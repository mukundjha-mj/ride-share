const mongoose = require('mongoose');

const rideSchema = new mongoose.Schema({
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    from: {
        type: String,
        required: [true, 'Starting point is required'],
        trim: true,
        maxlength: [100, 'Location cannot exceed 100 characters']
    },
    to: {
        type: String,
        required: [true, 'Destination is required'],
        trim: true,
        maxlength: [100, 'Location cannot exceed 100 characters']
    },
    timeStart: {
        type: Date,
        required: [true, 'Start time is required']
    },
    timeEnd: {
        type: Date,
        required: [true, 'End time is required']
    },
    seats: {
        type: Number,
        default: 1,
        min: [1, 'At least 1 seat required'],
        max: [4, 'Maximum 4 seats allowed']
    },
    status: {
        type: String,
        enum: ['open', 'filled', 'cancelled'],
        default: 'open'
    }
}, {
    timestamps: true
});

// Index for efficient querying of open rides
rideSchema.index({ status: 1, timeEnd: 1 });
rideSchema.index({ ownerId: 1 });

// Virtual to populate owner details
rideSchema.virtual('owner', {
    ref: 'User',
    localField: 'ownerId',
    foreignField: '_id',
    justOne: true
});

rideSchema.set('toJSON', { virtuals: true });
rideSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Ride', rideSchema);
