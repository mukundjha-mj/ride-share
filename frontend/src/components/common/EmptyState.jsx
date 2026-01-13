export function EmptyState({ icon, title, message }) {
    return (
        <div className="empty-state">
            {icon && <div className="empty-state-icon">{icon}</div>}
            {title && <h3 className="empty-state-title">{title}</h3>}
            {message && <p className="empty-state-text">{message}</p>}
        </div>
    );
}

export default EmptyState;
