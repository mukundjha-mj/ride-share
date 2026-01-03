require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');

// Import socket
const { initializeSocket } = require('./socket');

// Import routes
const authRoutes = require('./routes/auth');
const rideRoutes = require('./routes/rides');
const joinRoutes = require('./routes/join');
const chatRoutes = require('./routes/chat');

// Import jobs
const { startCleanupJob } = require('./jobs/cleanup');

// Import rate limiter
const { apiLimiter } = require('./middleware/rateLimiter');

const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
initializeSocket(server);

// Middleware
app.use(cors());
app.use(express.json({ limit: '10kb' }));
app.use(apiLimiter);

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use('/auth', authRoutes);
app.use('/rides', rideRoutes);
app.use('/', joinRoutes);
app.use('/', chatRoutes);

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        message: 'Internal server error'
    });
});

// Database connection and server start
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/rideshare';

mongoose.connect(MONGODB_URI)
    .then(() => {
        console.log('✅ Connected to MongoDB');
        startCleanupJob();

        // Use server.listen instead of app.listen for Socket.IO
        server.listen(PORT, () => {
            console.log(`🚀 Server running on port ${PORT}`);
        });
    })
    .catch((err) => {
        console.error('❌ MongoDB connection error:', err);
        process.exit(1);
    });

module.exports = { app, server };
