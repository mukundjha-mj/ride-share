const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema({
    joinRequestId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'JoinRequest',
        required: true
    },
    senderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    message: {
        type: String,
        required: [true, 'Message cannot be empty'],
        trim: true,
        maxlength: [1000, 'Message cannot exceed 1000 characters']
    },
    isSystemMessage: {
        type: Boolean,
        default: false
    },
    isEdited: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Index for fetching messages by join request
chatMessageSchema.index({ joinRequestId: 1, createdAt: 1 });

module.exports = mongoose.model('ChatMessage', chatMessageSchema);
