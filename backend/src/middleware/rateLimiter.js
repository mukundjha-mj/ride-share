const rateLimit = require('express-rate-limit');

// General API rate limiter
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // 100 requests per window
    message: {
        success: false,
        message: 'Too many requests, please try again later'
    },
    standardHeaders: true,
    legacyHeaders: false
});

// Stricter limiter for auth routes (prevent brute force)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10, // 10 auth attempts per window
    message: {
        success: false,
        message: 'Too many login attempts, please try again after 15 minutes'
    },
    standardHeaders: true,
    legacyHeaders: false
});

// Rate limiter for join requests (prevent spam)
const joinLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 5, // 5 join requests per minute
    message: {
        success: false,
        message: 'Too many join requests, please slow down'
    },
    standardHeaders: true,
    legacyHeaders: false
});

// Rate limiter for chat messages
const chatLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 30, // 30 messages per minute
    message: {
        success: false,
        message: 'Too many messages, please slow down'
    },
    standardHeaders: true,
    legacyHeaders: false
});

module.exports = {
    apiLimiter,
    authLimiter,
    joinLimiter,
    chatLimiter
};
