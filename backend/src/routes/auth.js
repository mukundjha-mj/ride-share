const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { validate } = require('../middleware/validate');
const { authLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

// Apply rate limiting to all auth routes
router.use(authLimiter);

// Generate JWT token
const generateToken = (userId) => {
    return jwt.sign(
        { userId },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );
};

// POST /auth/register
router.post('/register', validate('register'), async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Check if user exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'Email already registered'
            });
        }

        // Create user (password will be hashed by pre-save hook)
        const user = await User.create({
            name,
            email,
            passwordHash: password
        });

        // Generate token
        const token = generateToken(user._id);

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            data: { user, token }
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during registration'
        });
    }
});

// POST /auth/login
router.post('/login', validate('login'), async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find user
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        // Check password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        // Generate token
        const token = generateToken(user._id);

        res.json({
            success: true,
            message: 'Login successful',
            data: { user, token }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during login'
        });
    }
});

// GET /auth/me - Get current user
router.get('/me', require('../middleware/auth'), async (req, res) => {
    res.json({
        success: true,
        data: { user: req.user }
    });
});

// PATCH /auth/profile - Update user profile (name, password)
router.patch('/profile', require('../middleware/auth'), async (req, res) => {
    try {
        const { name, currentPassword, newPassword } = req.body;
        const user = await User.findById(req.userId);

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Update name if provided
        if (name && name.trim().length >= 2) {
            user.name = name.trim();
        }

        // Update password if provided
        if (newPassword) {
            if (!currentPassword) {
                return res.status(400).json({
                    success: false,
                    message: 'Current password is required to change password'
                });
            }

            const isMatch = await user.comparePassword(currentPassword);
            if (!isMatch) {
                return res.status(400).json({
                    success: false,
                    message: 'Current password is incorrect'
                });
            }

            if (newPassword.length < 6) {
                return res.status(400).json({
                    success: false,
                    message: 'New password must be at least 6 characters'
                });
            }

            user.passwordHash = newPassword; // Will be hashed by pre-save hook
        }

        await user.save();

        res.json({
            success: true,
            message: 'Profile updated successfully',
            data: { user }
        });
    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error updating profile'
        });
    }
});

module.exports = router;
