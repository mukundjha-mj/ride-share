export function LoadingSpinner({ size = 'md', className = '' }) {
    const sizeClass = size === 'sm' ? 'spinner-sm' : '';

    return (
        <div className={`flex justify-center items-center ${className}`}>
            <div className={`spinner ${sizeClass}`} />
        </div>
    );
}

export function FullPageSpinner() {
    return (
        <div className="flex justify-center items-center" style={{ minHeight: '100vh' }}>
            <div className="spinner" />
        </div>
    );
}

export default LoadingSpinner;
