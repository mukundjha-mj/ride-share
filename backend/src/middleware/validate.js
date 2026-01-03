const Joi = require('joi');

// Validation schemas
const schemas = {
    // Auth
    register: Joi.object({
        name: Joi.string().min(2).max(50).required().trim()
            .messages({
                'string.min': 'Name must be at least 2 characters',
                'string.max': 'Name cannot exceed 50 characters',
                'any.required': 'Name is required'
            }),
        email: Joi.string().email().required().lowercase().trim()
            .messages({
                'string.email': 'Please enter a valid email',
                'any.required': 'Email is required'
            }),
        password: Joi.string().min(6).max(128).required()
            .messages({
                'string.min': 'Password must be at least 6 characters',
                'any.required': 'Password is required'
            })
    }),

    login: Joi.object({
        email: Joi.string().email().required().lowercase().trim(),
        password: Joi.string().required()
    }),

    // Rides
    createRide: Joi.object({
        from: Joi.string().min(2).max(100).required().trim()
            .messages({
                'string.min': 'Starting point must be at least 2 characters',
                'any.required': 'Starting point is required'
            }),
        to: Joi.string().min(2).max(100).required().trim()
            .messages({
                'string.min': 'Destination must be at least 2 characters',
                'any.required': 'Destination is required'
            }),
        timeStart: Joi.date().iso().required()
            .messages({ 'any.required': 'Start time is required' }),
        timeEnd: Joi.date().iso().greater(Joi.ref('timeStart')).required()
            .messages({
                'date.greater': 'End time must be after start time',
                'any.required': 'End time is required'
            }),
        seats: Joi.number().integer().min(1).max(4).default(1)
    }),

    // Chat
    sendMessage: Joi.object({
        message: Joi.string().min(1).max(1000).required().trim()
            .messages({
                'string.max': 'Message cannot exceed 1000 characters',
                'any.required': 'Message cannot be empty'
            })
    })
};

// Validation middleware factory
const validate = (schemaName) => {
    return (req, res, next) => {
        const schema = schemas[schemaName];
        if (!schema) {
            return next();
        }

        const { error, value } = schema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true
        });

        if (error) {
            const errors = error.details.map(detail => detail.message);
            return res.status(400).json({
                success: false,
                message: errors[0],
                errors
            });
        }

        req.body = value;
        next();
    };
};

module.exports = { validate, schemas };
