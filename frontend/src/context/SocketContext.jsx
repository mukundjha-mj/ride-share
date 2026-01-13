import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import socketService from '@/services/socket';
import rideService from '@/services/rides';
import { useAuth } from '@/context/AuthContext';

const SocketContext = createContext(null);

export function SocketProvider({ children }) {
    const { isAuthenticated } = useAuth();
    const [unreadCount, setUnreadCount] = useState(0);

    // Fetch unread count
    const fetchUnreadCount = useCallback(async () => {
        if (!isAuthenticated) return;

        try {
            // Get my requests
            const myRequestsRes = await rideService.getMyRequests();
            let total = 0;

            if (myRequestsRes.success) {
                total += myRequestsRes.data.requests.reduce((acc, r) => acc + (r.unreadCount || 0), 0);
            }

            // Get my rides and their requests
            const myRidesRes = await rideService.getMyRides();
            if (myRidesRes.success) {
                for (const ride of myRidesRes.data.rides) {
                    const requestsRes = await rideService.getRideRequests(ride._id || ride.id);
                    if (requestsRes.success) {
                        total += requestsRes.data.requests.reduce((acc, r) => acc + (r.unreadCount || 0), 0);
                    }
                }
            }

            setUnreadCount(total);
        } catch (err) {
            console.error('Error fetching unread count:', err);
        }
    }, [isAuthenticated]);

    // Set up socket listeners
    useEffect(() => {
        if (!isAuthenticated) return;

        const handleNewMessage = () => {
            fetchUnreadCount();
        };

        const handleNewJoinRequest = () => {
            fetchUnreadCount();
        };

        socketService.on('new_message', handleNewMessage);
        socketService.on('new_join_request', handleNewJoinRequest);

        // Initial fetch
        fetchUnreadCount();

        return () => {
            socketService.off('new_message', handleNewMessage);
            socketService.off('new_join_request', handleNewJoinRequest);
        };
    }, [isAuthenticated, fetchUnreadCount]);

    const value = {
        unreadCount,
        hasUnread: unreadCount > 0,
        fetchUnreadCount,
    };

    return <SocketContext.Provider value={value}>{children}</SocketContext.Provider>;
}

export function useSocket() {
    const context = useContext(SocketContext);
    if (!context) {
        throw new Error('useSocket must be used within a SocketProvider');
    }
    return context;
}

export default SocketContext;
