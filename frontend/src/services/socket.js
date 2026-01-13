import { io } from 'socket.io-client';
import authService from './auth';

const WS_URL = import.meta.env.VITE_WS_URL;

if (!WS_URL) {
    console.error('VITE_WS_URL environment variable is not set');
}

class SocketService {
    constructor() {
        this.socket = null;
        this.isConnected = false;
        this.listeners = new Map();
    }

    connect() {
        if (this.socket?.connected) return;

        const token = authService.getToken();
        if (!token) return;

        this.socket = io(WS_URL, {
            auth: { token },
            transports: ['websocket'],
            reconnection: true,
            reconnectionAttempts: 5,
            reconnectionDelay: 1000,
        });

        this.socket.on('connect', () => {
            console.log('🔌 Socket connected');
            this.isConnected = true;
        });

        this.socket.on('disconnect', () => {
            console.log('🔌 Socket disconnected');
            this.isConnected = false;
        });

        this.socket.on('connect_error', (error) => {
            console.error('🔌 Socket connection error:', error.message);
        });

        // Re-register any existing listeners
        this.listeners.forEach((callbacks, event) => {
            callbacks.forEach((callback) => {
                this.socket.on(event, callback);
            });
        });
    }

    disconnect() {
        if (this.socket) {
            this.socket.disconnect();
            this.socket = null;
            this.isConnected = false;
        }
    }

    on(event, callback) {
        if (!this.listeners.has(event)) {
            this.listeners.set(event, new Set());
        }
        this.listeners.get(event).add(callback);

        if (this.socket) {
            this.socket.on(event, callback);
        }
    }

    off(event, callback) {
        if (this.listeners.has(event)) {
            this.listeners.get(event).delete(callback);
        }

        if (this.socket) {
            this.socket.off(event, callback);
        }
    }

    emit(event, data) {
        if (this.socket?.connected) {
            this.socket.emit(event, data);
        }
    }

    // Join a chat room
    joinChat(joinRequestId) {
        this.emit('join_chat', joinRequestId);
    }

    // Leave a chat room
    leaveChat(joinRequestId) {
        this.emit('leave_chat', joinRequestId);
    }

    // Join a ride room (for owners)
    joinRide(rideId) {
        this.emit('join_ride', rideId);
    }

    // Send typing indicator
    sendTyping(joinRequestId, isTyping) {
        this.emit('typing', { joinRequestId, isTyping });
    }
}

export const socketService = new SocketService();
export default socketService;
