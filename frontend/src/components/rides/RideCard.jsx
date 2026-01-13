import { format } from 'date-fns';
import { Card, CardBody } from '../common/Card';
import { Badge } from '../common/Badge';
import { Avatar } from '../common/Avatar';
import { Button } from '../common/Button';

export function RideCard({ ride, onJoin, showJoinButton = false, loading = false }) {
    const formatTime = (date) => {
        return format(new Date(date), 'MMM d, h:mm a');
    };

    return (
        <Card className="ride-card">
            <CardBody>
                <div className="ride-card-header">
                    <div className="ride-route">
                        <div className="ride-location">
                            <span className="ride-location-dot from" />
                            <span className="ride-location-text">{ride.from}</span>
                        </div>
                        <div className="ride-arrow">↓</div>
                        <div className="ride-location">
                            <span className="ride-location-dot to" />
                            <span className="ride-location-text">{ride.to}</span>
                        </div>
                    </div>
                    <Badge variant={ride.status === 'open' ? 'secondary' : 'gray'}>
                        {ride.status === 'open' ? 'Open' : ride.status === 'filled' ? 'Filled' : 'Cancelled'}
                    </Badge>
                </div>

                <div className="ride-meta">
                    <div className="ride-meta-item">
                        <span>📅</span>
                        <span>{formatTime(ride.timeStart)}</span>
                    </div>
                    <div className="ride-meta-item">
                        <span>⏰</span>
                        <span>Until {format(new Date(ride.timeEnd), 'h:mm a')}</span>
                    </div>
                    <div className="ride-meta-item">
                        <span>💺</span>
                        <span>{ride.seats} seat{ride.seats > 1 ? 's' : ''}</span>
                    </div>
                </div>

                <div className="ride-card-footer">
                    <div className="ride-owner">
                        <Avatar name={ride.owner?.name || 'User'} size="sm" />
                        <span className="ride-owner-name">{ride.owner?.name || 'Unknown'}</span>
                    </div>
                    {showJoinButton && ride.status === 'open' && (
                        <Button
                            variant="primary"
                            size="sm"
                            onClick={() => onJoin?.(ride)}
                            loading={loading}
                        >
                            Join Ride
                        </Button>
                    )}
                </div>
            </CardBody>
        </Card>
    );
}

export default RideCard;
