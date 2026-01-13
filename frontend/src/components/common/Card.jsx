export function Card({ children, className = '', hoverable = true, ...props }) {
    return (
        <div
            className={`card ${hoverable ? '' : 'no-hover'} ${className}`}
            style={hoverable ? {} : { transform: 'none' }}
            {...props}
        >
            {children}
        </div>
    );
}

export function CardBody({ children, className = '' }) {
    return <div className={`card-body ${className}`}>{children}</div>;
}

export default Card;
