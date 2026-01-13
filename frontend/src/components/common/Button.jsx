export function Button({
    children,
    variant = 'primary',
    size = 'md',
    block = false,
    loading = false,
    disabled = false,
    className = '',
    ...props
}) {
    const baseClass = 'btn';
    const variantClass = `btn-${variant}`;
    const sizeClass = size !== 'md' ? `btn-${size}` : '';
    const blockClass = block ? 'btn-block' : '';

    return (
        <button
            className={`${baseClass} ${variantClass} ${sizeClass} ${blockClass} ${className}`}
            disabled={disabled || loading}
            {...props}
        >
            {loading ? (
                <>
                    <span className="spinner spinner-sm" />
                    <span>Loading...</span>
                </>
            ) : (
                children
            )}
        </button>
    );
}

export default Button;
