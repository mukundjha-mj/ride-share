export function Badge({ children, variant = 'primary', className = '' }) {
    return <span className={`badge badge-${variant} ${className}`}>{children}</span>;
}

export function NotificationDot({ count }) {
    if (!count || count === 0) return null;

    return (
        <span className="notification-dot">
            {count > 9 ? '9+' : count}
        </span>
    );
}

export default Badge;
