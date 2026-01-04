/**
 * WebSocket Client Service
 * Calls the separate WebSocket server to emit real-time events
 */

const WEBSOCKET_SERVER_URL = process.env.WEBSOCKET_SERVER_URL;
const API_SECRET = process.env.WEBSOCKET_API_SECRET;

const emitEvent = async (endpoint, data) => {
    if (!WEBSOCKET_SERVER_URL) {
        console.log('⚠️ WEBSOCKET_SERVER_URL not configured, skipping socket emit');
        return;
    }

    try {
        const response = await fetch(`${WEBSOCKET_SERVER_URL}${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-secret': API_SECRET || ''
            },
            body: JSON.stringify(data)
        });

        if (!response.ok) {
            console.error(`❌ Socket emit failed: ${endpoint}`, await response.text());
        }
    } catch (error) {
        console.error(`❌ Socket emit error: ${endpoint}`, error.message);
    }
};

const socketEvents = {
    // New message in a chat
    newMessage: (joinRequestId, message) => {
        emitEvent('/emit/message', { joinRequestId, message });
    },

    // New join request for a ride (notify owner)
    newJoinRequest: (ownerId, rideId, joinRequest) => {
        emitEvent('/emit/join-request', { ownerId, rideId, joinRequest });
    },

    // Request was accepted (notify requester)
    requestAccepted: (userId, data) => {
        emitEvent('/emit/request-accepted', { userId, data });
    },

    // Request was rejected (notify requester)
    requestRejected: (userId, data) => {
        emitEvent('/emit/request-rejected', { userId, data });
    },

    // Ride was filled
    rideFilled: (rideId) => {
        emitEvent('/emit/ride-filled', { rideId });
    },

    // Message edited
    messageEdited: (joinRequestId, message) => {
        emitEvent('/emit/message-edited', { joinRequestId, message });
    },

    // Message deleted
    messageDeleted: (joinRequestId, messageId) => {
        emitEvent('/emit/message-deleted', { joinRequestId, messageId });
    },

    // Messages read
    messagesRead: (joinRequestId, userId, lastRead) => {
        emitEvent('/emit/messages-read', { joinRequestId, userId, lastRead });
    },

    // New ride posted
    newRide: (ride) => {
        emitEvent('/emit/new-ride', { ride });
    },

    // Ride cancelled/deleted
    rideCancelled: (rideId) => {
        emitEvent('/emit/ride-cancelled', { rideId });
    }
};

module.exports = { socketEvents };
