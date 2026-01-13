import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { MessageCircle, ChevronRight, User } from 'lucide-react';
import rideService from '@/services/rides';
import socketService from '@/services/socket';
import { Card, CardContent } from '@/components/ui/card';
import { Badge, NotificationDot } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { cn } from '@/lib/utils';

export function Chats() {
    const navigate = useNavigate();
    const [chats, setChats] = useState([]);
    const [loading, setLoading] = useState(true);

    const loadChats = useCallback(async () => {
        try {
            const chatItems = [];

            // Get my requests (where I'm the requester)
            const myRequestsRes = await rideService.getMyRequests();
            if (myRequestsRes.success) {
                for (const request of myRequestsRes.data.requests) {
                    const ride = request.rideId;
                    chatItems.push({
                        joinRequestId: request._id || request.id,
                        name: ride?.owner?.name || 'Unknown',
                        subtitle: `${ride?.from || ''} → ${ride?.to || ''}`,
                        status: request.status,
                        isOwner: false,
                        createdAt: new Date(request.createdAt),
                        unreadCount: request.unreadCount || 0,
                    });
                }
            }

            // Get my rides and their requests
            const myRidesRes = await rideService.getMyRides();
            if (myRidesRes.success) {
                for (const ride of myRidesRes.data.rides) {
                    const requestsRes = await rideService.getRideRequests(ride._id || ride.id);
                    if (requestsRes.success) {
                        for (const request of requestsRes.data.requests) {
                            chatItems.push({
                                joinRequestId: request._id || request.id,
                                name: request.requester?.name || 'Unknown',
                                subtitle: `${ride.from} → ${ride.to}`,
                                status: request.status,
                                isOwner: true,
                                createdAt: new Date(request.createdAt),
                                unreadCount: request.unreadCount || 0,
                            });
                        }
                    }
                }
            }

            // Sort by most recent
            chatItems.sort((a, b) => b.createdAt - a.createdAt);
            setChats(chatItems);
        } catch (err) {
            console.error('Error loading chats:', err);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        loadChats();

        const handleUpdate = () => loadChats();
        socketService.on('new_message', handleUpdate);
        socketService.on('new_join_request', handleUpdate);
        socketService.on('request_accepted', handleUpdate);
        socketService.on('request_rejected', handleUpdate);

        return () => {
            socketService.off('new_message', handleUpdate);
            socketService.off('new_join_request', handleUpdate);
            socketService.off('request_accepted', handleUpdate);
            socketService.off('request_rejected', handleUpdate);
        };
    }, [loadChats]);

    const getStatusVariant = (status) => {
        switch (status) {
            case 'pending':
                return 'warning';
            case 'accepted':
                return 'success';
            case 'rejected':
                return 'outline';
            default:
                return 'outline';
        }
    };

    const getStatusLabel = (status) => {
        switch (status) {
            case 'pending':
                return 'Active';
            case 'accepted':
                return 'Confirmed';
            case 'rejected':
                return 'Closed';
            default:
                return status;
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center py-20">
                <div className="flex flex-col items-center gap-4">
                    <div className="h-12 w-12 rounded-full border-4 border-primary-200 border-t-primary-500 animate-spin" />
                    <p className="text-slate-500 dark:text-slate-400">Loading messages...</p>
                </div>
            </div>
        );
    }

    if (chats.length === 0) {
        return (
            <Card className="overflow-hidden">
                <CardContent className="p-8 md:p-12 flex flex-col items-center justify-center text-center min-h-[300px]">
                    <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-600 flex items-center justify-center mb-6">
                        <MessageCircle className="h-10 w-10 text-slate-500 dark:text-slate-400" />
                    </div>
                    <h2 className="text-xl font-bold mb-3">No conversations yet</h2>
                    <p className="text-slate-500 dark:text-slate-400 max-w-md mx-auto">
                        Join a ride or wait for someone to request joining yours to start chatting
                    </p>
                </CardContent>
            </Card>
        );
    }

    return (
        <div className="space-y-3">
            {chats.map((chat) => (
                <Card
                    key={chat.joinRequestId}
                    className={cn(
                        "overflow-hidden cursor-pointer transition-all duration-200",
                        "hover:shadow-lg hover:-translate-y-0.5",
                        chat.unreadCount > 0 && "ring-2 ring-primary-500/20"
                    )}
                    onClick={() => navigate(`/chat/${chat.joinRequestId}?isOwner=${chat.isOwner}`)}
                >
                    <CardContent className="p-4">
                        <div className="flex items-center gap-4">
                            <div className="relative">
                                <Avatar className={cn(
                                    "h-12 w-12",
                                    chat.isOwner ? "ring-2 ring-primary-500/20" : "ring-2 ring-secondary-500/20"
                                )}>
                                    <AvatarFallback className={cn(
                                        chat.isOwner
                                            ? "bg-gradient-to-br from-primary-400 to-primary-600"
                                            : "bg-gradient-to-br from-secondary-400 to-secondary-600"
                                    )}>
                                        {chat.name.charAt(0)}
                                    </AvatarFallback>
                                </Avatar>
                                {chat.unreadCount > 0 && (
                                    <span className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white ring-2 ring-white dark:ring-slate-800">
                                        {chat.unreadCount > 9 ? '9+' : chat.unreadCount}
                                    </span>
                                )}
                            </div>

                            <div className="flex-1 min-w-0">
                                <div className="flex items-center justify-between gap-2 mb-1">
                                    <span className={cn(
                                        "font-semibold truncate",
                                        chat.unreadCount > 0 && "text-slate-900 dark:text-white"
                                    )}>
                                        {chat.name}
                                    </span>
                                    <Badge variant={getStatusVariant(chat.status)} className="shrink-0">
                                        {getStatusLabel(chat.status)}
                                    </Badge>
                                </div>
                                <p className="text-sm text-slate-500 dark:text-slate-400 truncate mb-1">
                                    {chat.subtitle}
                                </p>
                                <span className={cn(
                                    "text-xs font-medium",
                                    chat.isOwner ? "text-primary-500" : "text-secondary-500"
                                )}>
                                    {chat.isOwner ? 'Your ride' : 'Requested to join'}
                                </span>
                            </div>

                            <ChevronRight className="h-5 w-5 text-slate-400 shrink-0" />
                        </div>
                    </CardContent>
                </Card>
            ))}
        </div>
    );
}

export default Chats;
