import { forwardRef } from 'react';

export const Input = forwardRef(function Input(
    { label, error, className = '', type = 'text', ...props },
    ref
) {
    return (
        <div className="form-group">
            {label && <label className="form-label">{label}</label>}
            <input
                ref={ref}
                type={type}
                className={`form-input ${error ? 'error' : ''} ${className}`}
                {...props}
            />
            {error && <span className="form-error">{error}</span>}
        </div>
    );
});

export default Input;
