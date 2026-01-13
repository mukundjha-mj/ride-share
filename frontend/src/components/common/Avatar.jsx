export function Avatar({ name, variant = 'primary', size = 'md', className = '' }) {
    const initial = name ? name.charAt(0).toUpperCase() : '?';
    const sizeStyles = {
        sm: { width: 32, height: 32, fontSize: '0.875rem' },
        md: { width: 40, height: 40, fontSize: '1rem' },
        lg: { width: 48, height: 48, fontSize: '1.25rem' },
    };

    return (
        <div
            className={`avatar avatar-${variant} ${className}`}
            style={sizeStyles[size]}
        >
            {initial}
        </div>
    );
}

export default Avatar;
