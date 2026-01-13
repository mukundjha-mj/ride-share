import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { MapPin, Clock, Users, ArrowDown, Plus, Car, Sparkles } from 'lucide-react';
import rideService from '@/services/rides';
import socketService from '@/services/socket';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { cn } from '@/lib/utils';
import toast from 'react-hot-toast';

export function RideFeed() {
    const navigate = useNavigate();
    const [rides, setRides] = useState([]);
    const [loading, setLoading] = useState(true);
    const [joiningRideId, setJoiningRideId] = useState(null);

    const loadRides = useCallback(async () => {
        try {
            const response = await rideService.getRides();
            if (response.success) {
                setRides(response.data.rides);
            }
        } catch (err) {
            console.error('Error loading rides:', err);
            toast.error('Failed to load rides');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        loadRides();

        const handleNewRide = (ride) => {
            setRides((prev) => [ride, ...prev]);
        };

        const handleRideCancelled = ({ rideId }) => {
            setRides((prev) => prev.filter((r) => (r._id || r.id) !== rideId));
        };

        const handleRideFilled = ({ rideId }) => {
            setRides((prev) =>
                prev.map((r) =>
                    (r._id || r.id) === rideId ? { ...r, status: 'filled' } : r
                )
            );
        };

        socketService.on('new_ride', handleNewRide);
        socketService.on('ride_cancelled', handleRideCancelled);
        socketService.on('ride_filled', handleRideFilled);

        return () => {
            socketService.off('new_ride', handleNewRide);
            socketService.off('ride_cancelled', handleRideCancelled);
            socketService.off('ride_filled', handleRideFilled);
        };
    }, [loadRides]);

    const handleJoin = async (ride) => {
        const rideId = ride._id || ride.id;
        setJoiningRideId(rideId);

        try {
            const response = await rideService.joinRide(rideId);
            if (response.success) {
                toast.success('Join request sent!');
                navigate('/requests');
            } else {
                toast.error(response.message || 'Failed to join ride');
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to join ride';
            toast.error(message);
        } finally {
            setJoiningRideId(null);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center py-20">
                <div className="flex flex-col items-center gap-4">
                    <div className="h-12 w-12 rounded-full border-4 border-primary-200 border-t-primary-500 animate-spin" />
                    <p className="text-slate-500 dark:text-slate-400">Finding rides...</p>
                </div>
            </div>
        );
    }

    if (rides.length === 0) {
        return (
            <>
                {/* Empty State Bento Grid */}
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {/* Hero Card */}
                    <Card className="md:col-span-2 lg:col-span-3 overflow-hidden">
                        <CardContent className="p-8 md:p-12 flex flex-col items-center justify-center text-center min-h-[300px] relative">
                            <div className="absolute inset-0 bg-gradient-to-br from-primary-500/10 via-transparent to-secondary-500/10" />
                            <div className="relative z-10">
                                <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-primary-500 to-secondary-500 flex items-center justify-center mb-6 mx-auto shadow-2xl shadow-primary-500/30">
                                    <Car className="h-10 w-10 text-white" />
                                </div>
                                <h2 className="text-2xl md:text-3xl font-bold mb-3 bg-gradient-to-r from-slate-900 to-slate-600 dark:from-white dark:to-slate-300 bg-clip-text text-transparent">
                                    No rides available right now
                                </h2>
                                <p className="text-slate-500 dark:text-slate-400 mb-8 max-w-md mx-auto">
                                    Be the first to post a ride and help others travel with you. It's quick and easy!
                                </p>
                                <Button size="lg" onClick={() => navigate('/create-ride')} className="gap-2">
                                    <Plus className="h-5 w-5" />
                                    Post a Ride
                                </Button>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Feature Cards */}
                    <Card>
                        <CardContent className="p-6">
                            <div className="w-12 h-12 rounded-2xl bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center mb-4">
                                <Users className="h-6 w-6 text-primary-600 dark:text-primary-400" />
                            </div>
                            <h3 className="font-semibold mb-2">Connect with Others</h3>
                            <p className="text-sm text-slate-500 dark:text-slate-400">
                                Find travel companions heading the same way
                            </p>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardContent className="p-6">
                            <div className="w-12 h-12 rounded-2xl bg-secondary-100 dark:bg-secondary-900/30 flex items-center justify-center mb-4">
                                <MapPin className="h-6 w-6 text-secondary-600 dark:text-secondary-400" />
                            </div>
                            <h3 className="font-semibold mb-2">Share Your Route</h3>
                            <p className="text-sm text-slate-500 dark:text-slate-400">
                                Post your ride and let others join you
                            </p>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardContent className="p-6">
                            <div className="w-12 h-12 rounded-2xl bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center mb-4">
                                <Sparkles className="h-6 w-6 text-amber-600 dark:text-amber-400" />
                            </div>
                            <h3 className="font-semibold mb-2">Save Together</h3>
                            <p className="text-sm text-slate-500 dark:text-slate-400">
                                Split costs and reduce your carbon footprint
                            </p>
                        </CardContent>
                    </Card>
                </div>

                {/* FAB */}
                <button
                    onClick={() => navigate('/create-ride')}
                    className="fixed bottom-24 right-4 md:right-8 z-50 flex items-center gap-2 px-5 py-3.5 rounded-full bg-gradient-to-r from-primary-500 to-primary-600 text-white font-medium shadow-xl shadow-primary-500/30 hover:shadow-2xl hover:shadow-primary-500/40 transition-all duration-300 hover:-translate-y-1"
                >
                    <Plus className="h-5 w-5" />
                    <span>Post Ride</span>
                </button>
            </>
        );
    }

    return (
        <>
            {/* Stats Banner */}
            <Card className="mb-6 overflow-hidden">
                <CardContent className="p-0">
                    <div className="bg-gradient-to-r from-primary-500 to-secondary-500 p-4 md:p-6">
                        <div className="flex items-center justify-between text-white">
                            <div>
                                <p className="text-sm opacity-80">Available now</p>
                                <h2 className="text-2xl md:text-3xl font-bold">{rides.length} Rides</h2>
                            </div>
                            <div className="w-14 h-14 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center">
                                <Car className="h-7 w-7" />
                            </div>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Bento Grid */}
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {rides.map((ride, index) => (
                    <RideCard
                        key={ride._id || ride.id}
                        ride={ride}
                        onJoin={handleJoin}
                        loading={joiningRideId === (ride._id || ride.id)}
                        featured={index === 0}
                    />
                ))}
            </div>

            {/* FAB */}
            <button
                onClick={() => navigate('/create-ride')}
                className="fixed bottom-24 right-4 md:right-8 z-50 flex items-center gap-2 px-5 py-3.5 rounded-full bg-gradient-to-r from-primary-500 to-primary-600 text-white font-medium shadow-xl shadow-primary-500/30 hover:shadow-2xl hover:shadow-primary-500/40 transition-all duration-300 hover:-translate-y-1"
            >
                <Plus className="h-5 w-5" />
                <span className="hidden sm:inline">Post Ride</span>
            </button>
        </>
    );
}

function RideCard({ ride, onJoin, loading, featured }) {
    return (
        <Card className={cn("overflow-hidden group", featured && "sm:col-span-2 lg:col-span-1")}>
            <CardContent className="p-0">
                {/* Route visualization */}
                <div className="p-5 pb-4">
                    <div className="flex items-start gap-3">
                        <div className="flex flex-col items-center">
                            <div className="w-3 h-3 rounded-full bg-gradient-to-r from-secondary-400 to-secondary-500 ring-4 ring-secondary-100 dark:ring-secondary-900/30" />
                            <div className="w-0.5 h-8 bg-gradient-to-b from-secondary-400 to-primary-400 my-1" />
                            <div className="w-3 h-3 rounded-full bg-gradient-to-r from-primary-400 to-primary-500 ring-4 ring-primary-100 dark:ring-primary-900/30" />
                        </div>
                        <div className="flex-1 space-y-3 min-w-0">
                            <div>
                                <p className="text-xs text-slate-400 uppercase tracking-wider mb-0.5">From</p>
                                <p className="font-semibold truncate">{ride.from}</p>
                            </div>
                            <div>
                                <p className="text-xs text-slate-400 uppercase tracking-wider mb-0.5">To</p>
                                <p className="font-semibold truncate">{ride.to}</p>
                            </div>
                        </div>
                        <Badge variant={ride.status === 'open' ? 'success' : 'outline'}>
                            {ride.status === 'open' ? 'Open' : 'Filled'}
                        </Badge>
                    </div>
                </div>

                {/* Meta info */}
                <div className="px-5 pb-4 flex flex-wrap gap-3 text-sm text-slate-500 dark:text-slate-400">
                    <div className="flex items-center gap-1.5">
                        <Clock className="h-4 w-4" />
                        <span>{format(new Date(ride.timeStart), 'MMM d, h:mm a')}</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                        <Users className="h-4 w-4" />
                        <span>{ride.seats} seat{ride.seats > 1 ? 's' : ''}</span>
                    </div>
                </div>

                {/* Footer */}
                <div className="px-5 py-4 border-t border-slate-100 dark:border-slate-700/50 flex items-center justify-between bg-slate-50/50 dark:bg-slate-800/30">
                    <div className="flex items-center gap-3">
                        <Avatar className="h-9 w-9">
                            <AvatarFallback className="text-sm">
                                {ride.owner?.name?.charAt(0) || '?'}
                            </AvatarFallback>
                        </Avatar>
                        <span className="text-sm font-medium truncate max-w-[120px]">
                            {ride.owner?.name || 'Unknown'}
                        </span>
                    </div>
                    {ride.status === 'open' && (
                        <Button
                            size="sm"
                            onClick={() => onJoin?.(ride)}
                            loading={loading}
                            className="shrink-0"
                        >
                            Join Ride
                        </Button>
                    )}
                </div>
            </CardContent>
        </Card>
    );
}

export default RideFeed;
