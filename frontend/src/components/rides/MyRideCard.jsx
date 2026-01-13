import { format } from 'date-fns';
import { useNavigate } from 'react-router-dom';
import { Card, CardBody } from '../common/Card';
import { Badge, NotificationDot } from '../common/Badge';
import { Button } from '../common/Button';

export function MyRideCard({ ride, onCancel, loading = false }) {
    const navigate = useNavigate();

    const formatTime = (date) => {
        return format(new Date(date), 'MMM d, h:mm a');
    };

    const getStatusBadge = () => {
        switch (ride.status) {
            case 'open':
                return <Badge variant="secondary">Open</Badge>;
            case 'filled':
                return <Badge variant="primary">Filled</Badge>;
            case 'cancelled':
                return <Badge variant="gray">Cancelled</Badge>;
            default:
                return null;
        }
    };

    const pendingCount = ride.pendingRequestCount || 0;

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
                    {getStatusBadge()}
                </div>

                <div className="ride-meta">
                    <div className="ride-meta-item">
                        <span>📅</span>
                        <span>{formatTime(ride.timeStart)}</span>
                    </div>
                    <div className="ride-meta-item">
                        <span>💺</span>
                        <span>{ride.seats} seat{ride.seats > 1 ? 's' : ''}</span>
                    </div>
                </div>

                <div className="ride-card-footer">
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => navigate(`/rides/${ride._id || ride.id}/requests`)}
                        style={{ position: 'relative' }}
                    >
                        View Requests
                        {pendingCount > 0 && <NotificationDot count={pendingCount} />}
                    </Button>

                    {ride.status === 'open' && (
                        <Button
                            variant="danger"
                            size="sm"
                            onClick={() => onCancel?.(ride)}
                            loading={loading}
                        >
                            Cancel
                        </Button>
                    )}
                </div>
            </CardBody>
        </Card>
    );
}

export default MyRideCard;
