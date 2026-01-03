const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

let io;

/**
 * Initialize Socket.IO with the HTTP server
 */
const initializeSocket = (httpServer) => {
    io = new Server(httpServer, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST']
        }
    });

    // Auth middleware for socket connections
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth.token;

            if (!token) {
                return next(new Error('Authentication required'));
            }

            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const user = await User.findById(decoded.userId);

            if (!user) {
                return next(new Error('User not found'));
            }

            socket.userId = user._id.toString();
            socket.user = user;
            next();
        } catch (error) {
            next(new Error('Invalid token'));
        }
    });

    io.on('connection', (socket) => {
        console.log(`🔌 User connected: ${socket.user.name} (${socket.userId})`);

        // Join user's personal room for notifications
        socket.join(`user:${socket.userId}`);

        // Join a chat room
        socket.on('join_chat', (joinRequestId) => {
            socket.join(`chat:${joinRequestId}`);
            console.log(`💬 ${socket.user.name} joined chat: ${joinRequestId}`);
        });

        // Leave a chat room
        socket.on('leave_chat', (joinRequestId) => {
            socket.leave(`chat:${joinRequestId}`);
        });

        // Join ride room (for owners to get notified of new requests)
        socket.on('join_ride', (rideId) => {
            socket.join(`ride:${rideId}`);
            console.log(`🚗 ${socket.user.name} joined ride room: ${rideId}`);
        });

        socket.on('disconnect', () => {
            console.log(`🔌 User disconnected: ${socket.user.name}`);
        });
    });

    console.log('🔌 Socket.IO initialized');
    return io;
};

/**
 * Get the Socket.IO instance
 */
const getIO = () => {
    if (!io) {
        throw new Error('Socket.IO not initialized');
    }
    return io;
};

/**
 * Emit events - utility functions
 */
const socketEvents = {
    // New message in a chat
    newMessage: (joinRequestId, message) => {
        if (io) {
            io.to(`chat:${joinRequestId}`).emit('new_message', message);
        }
    },

    // New join request for a ride (notify owner)
    newJoinRequest: (rideId, joinRequest) => {
        if (io) {
            io.to(`ride:${rideId}`).emit('new_join_request', joinRequest);
        }
    },

    // Request was accepted (notify requester)
    requestAccepted: (userId, data) => {
        if (io) {
            io.to(`user:${userId}`).emit('request_accepted', data);
        }
    },

    // Request was rejected (notify requester)
    requestRejected: (userId, data) => {
        if (io) {
            io.to(`user:${userId}`).emit('request_rejected', data);
        }
    },

    // Ride was filled (notify all in ride room)
    rideFilled: (rideId) => {
        if (io) {
            io.to(`ride:${rideId}`).emit('ride_filled', { rideId });
        }
    }
};

module.exports = { initializeSocket, getIO, socketEvents };
