import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { Clock, Users, MapPin, Eye, X, Car, Plus } from 'lucide-react';
import rideService from '@/services/rides';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription,
    DialogFooter,
} from '@/components/ui/dialog';
import toast from 'react-hot-toast';

export function MyRides() {
    const navigate = useNavigate();
    const [rides, setRides] = useState([]);
    const [loading, setLoading] = useState(true);
    const [cancellingRide, setCancellingRide] = useState(null);

    const loadRides = useCallback(async () => {
        try {
            const response = await rideService.getMyRides();
            if (response.success) {
                setRides(response.data.rides);
            }
        } catch (err) {
            console.error('Error loading rides:', err);
            toast.error('Failed to load your rides');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        loadRides();
    }, [loadRides]);

    const handleConfirmCancel = async () => {
        if (!cancellingRide) return;

        try {
            const response = await rideService.cancelRide(cancellingRide._id || cancellingRide.id);
            if (response.success) {
                toast.success('Ride cancelled');
                setRides((prev) =>
                    prev.map((r) =>
                        (r._id || r.id) === (cancellingRide._id || cancellingRide.id)
                            ? { ...r, status: 'cancelled' }
                            : r
                    )
                );
            } else {
                toast.error(response.message || 'Failed to cancel ride');
            }
        } catch (err) {
            toast.error(err.response?.data?.message || 'Failed to cancel ride');
        } finally {
            setCancellingRide(null);
        }
    };

    const getStatusVariant = (status) => {
        switch (status) {
            case 'open':
                return 'success';
            case 'filled':
                return 'default';
            case 'cancelled':
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
                    <p className="text-slate-500 dark:text-slate-400">Loading your rides...</p>
                </div>
            </div>
        );
    }

    if (rides.length === 0) {
        return (
            <Card className="overflow-hidden">
                <CardContent className="p-8 md:p-12 flex flex-col items-center justify-center text-center min-h-[300px]">
                    <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-600 flex items-center justify-center mb-6">
                        <Car className="h-10 w-10 text-slate-500 dark:text-slate-400" />
                    </div>
                    <h2 className="text-xl font-bold mb-3">No rides posted yet</h2>
                    <p className="text-slate-500 dark:text-slate-400 mb-8 max-w-md mx-auto">
                        Create a ride to find travel companions heading your way
                    </p>
                    <Button onClick={() => navigate('/create-ride')} className="gap-2">
                        <Plus className="h-5 w-5" />
                        Post Your First Ride
                    </Button>
                </CardContent>
            </Card>
        );
    }

    return (
        <>
            {/* Stats */}
            <div className="grid grid-cols-3 gap-4 mb-6">
                <Card>
                    <CardContent className="p-4 text-center">
                        <p className="text-2xl font-bold text-primary-600">{rides.filter(r => r.status === 'open').length}</p>
                        <p className="text-xs text-slate-500">Open</p>
                    </CardContent>
                </Card>
                <Card>
                    <CardContent className="p-4 text-center">
                        <p className="text-2xl font-bold text-secondary-600">{rides.filter(r => r.status === 'filled').length}</p>
                        <p className="text-xs text-slate-500">Filled</p>
                    </CardContent>
                </Card>
                <Card>
                    <CardContent className="p-4 text-center">
                        <p className="text-2xl font-bold text-slate-600">{rides.filter(r => r.status === 'cancelled').length}</p>
                        <p className="text-xs text-slate-500">Cancelled</p>
                    </CardContent>
                </Card>
            </div>

            {/* Rides Grid */}
            <div className="grid gap-4 sm:grid-cols-2">
                {rides.map((ride) => (
                    <Card key={ride._id || ride.id} className="overflow-hidden">
                        <CardContent className="p-0">
                            <div className="p-5">
                                <div className="flex items-start justify-between gap-3 mb-4">
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center gap-2 text-sm text-slate-500 mb-1">
                                            <MapPin className="h-4 w-4 text-secondary-500" />
                                            <span className="truncate">{ride.from}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-sm text-slate-500">
                                            <MapPin className="h-4 w-4 text-primary-500" />
                                            <span className="truncate">{ride.to}</span>
                                        </div>
                                    </div>
                                    <Badge variant={getStatusVariant(ride.status)}>
                                        {ride.status.charAt(0).toUpperCase() + ride.status.slice(1)}
                                    </Badge>
                                </div>

                                <div className="flex flex-wrap gap-3 text-xs text-slate-500">
                                    <div className="flex items-center gap-1.5">
                                        <Clock className="h-3.5 w-3.5" />
                                        <span>{format(new Date(ride.timeStart), 'MMM d, h:mm a')}</span>
                                    </div>
                                    <div className="flex items-center gap-1.5">
                                        <Users className="h-3.5 w-3.5" />
                                        <span>{ride.seats} seat{ride.seats > 1 ? 's' : ''}</span>
                                    </div>
                                </div>
                            </div>

                            <div className="px-5 py-3 border-t border-slate-100 dark:border-slate-700/50 flex gap-2 bg-slate-50/50 dark:bg-slate-800/30">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    className="flex-1 gap-2"
                                    onClick={() => navigate(`/rides/${ride._id || ride.id}/requests`)}
                                >
                                    <Eye className="h-4 w-4" />
                                    <span>Requests</span>
                                </Button>
                                {ride.status === 'open' && (
                                    <Button
                                        variant="destructive"
                                        size="sm"
                                        className="gap-2"
                                        onClick={() => setCancellingRide(ride)}
                                    >
                                        <X className="h-4 w-4" />
                                    </Button>
                                )}
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Cancel Dialog */}
            <Dialog open={!!cancellingRide} onOpenChange={() => setCancellingRide(null)}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Cancel this ride?</DialogTitle>
                        <DialogDescription>
                            This action cannot be undone. All pending requests will be notified.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:gap-0">
                        <Button variant="outline" onClick={() => setCancellingRide(null)}>
                            Keep Ride
                        </Button>
                        <Button variant="destructive" onClick={handleConfirmCancel}>
                            Cancel Ride
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </>
    );
}

export default MyRides;
