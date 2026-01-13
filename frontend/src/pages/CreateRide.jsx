import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MapPin, Clock, Users, Sparkles } from 'lucide-react';
import rideService from '@/services/rides';
import { PageLayout } from '@/components/layout/Layout';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import toast from 'react-hot-toast';

export function CreateRide() {
    const navigate = useNavigate();
    const [from, setFrom] = useState('');
    const [to, setTo] = useState('');
    const [timeStart, setTimeStart] = useState('');
    const [timeEnd, setTimeEnd] = useState('');
    const [seats, setSeats] = useState(1);
    const [loading, setLoading] = useState(false);
    const [errors, setErrors] = useState({});

    const validate = () => {
        const newErrors = {};
        if (!from.trim()) newErrors.from = 'Starting point is required';
        if (!to.trim()) newErrors.to = 'Destination is required';
        if (!timeStart) newErrors.timeStart = 'Start time is required';
        if (!timeEnd) newErrors.timeEnd = 'End time is required';

        if (timeStart && timeEnd) {
            const start = new Date(timeStart);
            const end = new Date(timeEnd);
            if (start >= end) {
                newErrors.timeEnd = 'End time must be after start time';
            }
            if (start < new Date()) {
                newErrors.timeStart = 'Start time cannot be in the past';
            }
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        setLoading(true);

        try {
            const response = await rideService.createRide({
                from: from.trim(),
                to: to.trim(),
                timeStart: new Date(timeStart).toISOString(),
                timeEnd: new Date(timeEnd).toISOString(),
                seats,
            });

            if (response.success) {
                toast.success('Ride posted successfully!');
                navigate('/my-rides');
            } else {
                toast.error(response.message || 'Failed to create ride');
            }
        } catch (err) {
            toast.error(err.response?.data?.message || 'Failed to create ride');
        } finally {
            setLoading(false);
        }
    };

    const getMinDateTime = () => {
        const now = new Date();
        now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
        return now.toISOString().slice(0, 16);
    };

    return (
        <PageLayout title="Post a Ride" showBack>
            <Card className="max-w-lg mx-auto overflow-hidden">
                <CardHeader className="bg-gradient-to-r from-primary-500 to-secondary-500 text-white">
                    <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-2xl bg-white/20 backdrop-blur-sm flex items-center justify-center">
                            <Sparkles className="h-6 w-6" />
                        </div>
                        <div>
                            <CardTitle className="text-white">Create New Ride</CardTitle>
                            <p className="text-white/80 text-sm">Share your journey with others</p>
                        </div>
                    </div>
                </CardHeader>
                <CardContent className="p-6">
                    <form onSubmit={handleSubmit} className="space-y-5">
                        {/* From */}
                        <div className="relative">
                            <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-secondary-500" />
                            <Input
                                placeholder="Starting point"
                                value={from}
                                onChange={(e) => setFrom(e.target.value)}
                                error={errors.from}
                                className="pl-12"
                            />
                        </div>

                        {/* To */}
                        <div className="relative">
                            <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-primary-500" />
                            <Input
                                placeholder="Destination"
                                value={to}
                                onChange={(e) => setTo(e.target.value)}
                                error={errors.to}
                                className="pl-12"
                            />
                        </div>

                        {/* Time Grid */}
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <label className="text-sm font-medium flex items-center gap-2">
                                    <Clock className="h-4 w-4 text-slate-400" />
                                    Start Time
                                </label>
                                <input
                                    type="datetime-local"
                                    className={cn(
                                        "flex h-11 w-full rounded-xl border border-slate-200 bg-white/50 backdrop-blur-sm px-4 py-2 text-sm transition-all duration-200",
                                        "focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500",
                                        "dark:border-slate-700 dark:bg-slate-800/50",
                                        errors.timeStart && "border-red-500"
                                    )}
                                    value={timeStart}
                                    onChange={(e) => setTimeStart(e.target.value)}
                                    min={getMinDateTime()}
                                />
                                {errors.timeStart && (
                                    <p className="text-xs text-red-500">{errors.timeStart}</p>
                                )}
                            </div>

                            <div className="space-y-2">
                                <label className="text-sm font-medium flex items-center gap-2">
                                    <Clock className="h-4 w-4 text-slate-400" />
                                    End Time
                                </label>
                                <input
                                    type="datetime-local"
                                    className={cn(
                                        "flex h-11 w-full rounded-xl border border-slate-200 bg-white/50 backdrop-blur-sm px-4 py-2 text-sm transition-all duration-200",
                                        "focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500",
                                        "dark:border-slate-700 dark:bg-slate-800/50",
                                        errors.timeEnd && "border-red-500"
                                    )}
                                    value={timeEnd}
                                    onChange={(e) => setTimeEnd(e.target.value)}
                                    min={timeStart || getMinDateTime()}
                                />
                                {errors.timeEnd && (
                                    <p className="text-xs text-red-500">{errors.timeEnd}</p>
                                )}
                            </div>
                        </div>

                        {/* Seats */}
                        <div className="space-y-3">
                            <label className="text-sm font-medium flex items-center gap-2">
                                <Users className="h-4 w-4 text-slate-400" />
                                Available Seats
                            </label>
                            <div className="grid grid-cols-4 gap-2">
                                {[1, 2, 3, 4].map((num) => (
                                    <button
                                        key={num}
                                        type="button"
                                        className={cn(
                                            "h-12 rounded-xl font-semibold transition-all duration-200",
                                            seats === num
                                                ? "bg-gradient-to-r from-primary-500 to-primary-600 text-white shadow-lg shadow-primary-500/30"
                                                : "bg-slate-100 text-slate-700 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700"
                                        )}
                                        onClick={() => setSeats(num)}
                                    >
                                        {num}
                                    </button>
                                ))}
                            </div>
                        </div>

                        <Button type="submit" className="w-full" size="lg" loading={loading}>
                            Post Ride
                        </Button>
                    </form>
                </CardContent>
            </Card>
        </PageLayout>
    );
}

export default CreateRide;
