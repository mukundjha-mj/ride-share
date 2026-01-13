import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { MapPin, Clock, User, Send } from 'lucide-react';
import rideService from '@/services/rides';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';

export function MyRequests() {
    const navigate = useNavigate();
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);

    const loadRequests = useCallback(async () => {
        try {
            const response = await rideService.getMyRequests();
            if (response.success) {
                setRequests(response.data.requests);
            }
        } catch (err) {
            console.error('Error loading requests:', err);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        loadRequests();
    }, [loadRequests]);

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
            <div className="flex items-center justify-center py-20">
                <div className="flex flex-col items-center gap-4">
                    <div className="h-12 w-12 rounded-full border-4 border-primary-200 border-t-primary-500 animate-spin" />
                    <p className="text-slate-500 dark:text-slate-400">Loading requests...</p>
                </div>
            </div>
        );
    }

    if (requests.length === 0) {
        return (
            <Card className="overflow-hidden">
                <CardContent className="p-8 md:p-12 flex flex-col items-center justify-center text-center min-h-[300px]">
                    <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-600 flex items-center justify-center mb-6">
                        <Send className="h-10 w-10 text-slate-500 dark:text-slate-400" />
                    </div>
                    <h2 className="text-xl font-bold mb-3">No requests sent</h2>
                    <p className="text-slate-500 dark:text-slate-400 max-w-md mx-auto">
                        Browse available rides and send join requests to get started
                    </p>
                </CardContent>
            </Card>
        );
    }

    return (
        <div className="space-y-3">
            {requests.map((request) => {
                const ride = request.rideId;
                return (
                    <Card
                        key={request._id || request.id}
                        className={cn(
                            "overflow-hidden cursor-pointer transition-all duration-200",
                            "hover:shadow-lg hover:-translate-y-0.5"
                        )}
                        onClick={() => navigate(`/chat/${request._id || request.id}?isOwner=false`)}
                    >
                        <CardContent className="p-4">
                            {/* Route */}
                            <div className="flex items-start gap-3 mb-4">
                                <div className="flex flex-col items-center pt-1">
                                    <div className="w-2.5 h-2.5 rounded-full bg-secondary-500 ring-2 ring-secondary-100 dark:ring-secondary-900/30" />
                                    <div className="w-0.5 h-6 bg-gradient-to-b from-secondary-400 to-primary-400 my-0.5" />
                                    <div className="w-2.5 h-2.5 rounded-full bg-primary-500 ring-2 ring-primary-100 dark:ring-primary-900/30" />
                                </div>
                                <div className="flex-1 min-w-0">
                                    <p className="font-medium truncate">{ride?.from || 'Unknown'}</p>
                                    <p className="font-medium truncate text-slate-600 dark:text-slate-300 mt-3">{ride?.to || 'Unknown'}</p>
                                </div>
                                <Badge variant={getStatusVariant(request.status)}>
                                    {request.status.charAt(0).toUpperCase() + request.status.slice(1)}
                                </Badge>
                            </div>

                            {/* Meta */}
                            <div className="flex flex-wrap gap-4 text-xs text-slate-500 dark:text-slate-400">
                                <div className="flex items-center gap-1.5">
                                    <Clock className="h-3.5 w-3.5" />
                                    <span>
                                        {ride?.timeStart
                                            ? format(new Date(ride.timeStart), 'MMM d, h:mm a')
                                            : 'Unknown'}
                                    </span>
                                </div>
                                <div className="flex items-center gap-1.5">
                                    <User className="h-3.5 w-3.5" />
                                    <span>{ride?.owner?.name || 'Unknown'}</span>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                );
            })}
        </div>
    );
}

export default MyRequests;
