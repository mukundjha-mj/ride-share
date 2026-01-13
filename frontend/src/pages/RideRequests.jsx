import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { MessageCircle, Check, Mail } from 'lucide-react';
import rideService from '@/services/rides';
import { PageLayout } from '@/components/layout/Layout';
import { Card, CardContent } from '@/components/ui/card';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge, NotificationDot } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import toast from 'react-hot-toast';

export function RideRequests() {
    const { rideId } = useParams();
    const navigate = useNavigate();
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);
    const [acceptingId, setAcceptingId] = useState(null);

    const loadRequests = useCallback(async () => {
        try {
            const response = await rideService.getRideRequests(rideId);
            if (response.success) {
                setRequests(response.data.requests);
            }
        } catch (err) {
            console.error('Error loading requests:', err);
            toast.error('Failed to load requests');
        } finally {
            setLoading(false);
        }
    }, [rideId]);

    useEffect(() => {
        loadRequests();
    }, [loadRequests]);

    const handleAccept = async (request) => {
        const requestId = request._id || request.id;
        setAcceptingId(requestId);

        try {
            const response = await rideService.acceptRequest(requestId);
            if (response.success) {
                toast.success(`Request accepted!`);
                loadRequests();
            } else {
                toast.error(response.message || 'Failed to accept request');
            }
        } catch (err) {
            toast.error(err.response?.data?.message || 'Failed to accept request');
        } finally {
            setAcceptingId(null);
        }
    };

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

    if (loading) {
        return (
            <PageLayout title="Join Requests" showBack>
                <div className="flex items-center justify-center py-20">
                    <div className="h-12 w-12 rounded-full border-4 border-primary-200 border-t-primary-500 animate-spin" />
                </div>
            </PageLayout>
        );
    }

    if (requests.length === 0) {
        return (
            <PageLayout title="Join Requests" showBack>
                <Card className="overflow-hidden">
                    <CardContent className="p-8 md:p-12 flex flex-col items-center justify-center text-center min-h-[300px]">
                        <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-600 flex items-center justify-center mb-6">
                            <Mail className="h-10 w-10 text-slate-500 dark:text-slate-400" />
                        </div>
                        <h2 className="text-xl font-bold mb-3">No requests yet</h2>
                        <p className="text-slate-500 dark:text-slate-400 max-w-md mx-auto">
                            Wait for someone to request joining your ride
                        </p>
                    </CardContent>
                </Card>
            </PageLayout>
        );
    }

    return (
        <PageLayout title="Join Requests" showBack>
            <div className="space-y-3">
                {requests.map((request) => (
                    <Card key={request._id || request.id} className="overflow-hidden">
                        <CardContent className="p-4">
                            <div className="flex items-center gap-4 mb-4">
                                <div className="relative">
                                    <Avatar className="h-12 w-12 ring-2 ring-slate-100 dark:ring-slate-700">
                                        <AvatarFallback>
                                            {request.requester?.name?.charAt(0) || '?'}
                                        </AvatarFallback>
                                    </Avatar>
                                    {request.unreadCount > 0 && (
                                        <span className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white">
                                            {request.unreadCount > 9 ? '9+' : request.unreadCount}
                                        </span>
                                    )}
                                </div>

                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center justify-between gap-2 mb-1">
                                        <span className="font-semibold truncate">
                                            {request.requester?.name || 'Unknown'}
                                        </span>
                                        <Badge variant={getStatusVariant(request.status)}>
                                            {request.status.charAt(0).toUpperCase() + request.status.slice(1)}
                                        </Badge>
                                    </div>
                                    <p className="text-sm text-slate-500 dark:text-slate-400 truncate">
                                        {request.requester?.email}
                                    </p>
                                </div>
                            </div>

                            <div className="flex gap-2">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    className="flex-1 gap-2"
                                    onClick={() => navigate(`/chat/${request._id || request.id}?isOwner=true`)}
                                >
                                    <MessageCircle className="h-4 w-4" />
                                    Chat
                                </Button>
                                {request.status === 'pending' && (
                                    <Button
                                        variant="secondary"
                                        size="sm"
                                        className="flex-1 gap-2"
                                        onClick={() => handleAccept(request)}
                                        loading={acceptingId === (request._id || request.id)}
                                    >
                                        <Check className="h-4 w-4" />
                                        Accept
                                    </Button>
                                )}
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>
        </PageLayout>
    );
}

export default RideRequests;
