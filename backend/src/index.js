require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');

// Import routes
const authRoutes = require('./routes/auth');
const rideRoutes = require('./routes/rides');
const joinRoutes = require('./routes/join');
const chatRoutes = require('./routes/chat');

// Import rate limiter
const { apiLimiter } = require('./middleware/rateLimiter');

const app = express();

// Database connection - requires MONGODB_URI from environment
const MONGODB_URI = process.env.MONGODB_URI;
let isConnected = false;

const connectDB = async () => {
    if (!MONGODB_URI) {
        throw new Error('MONGODB_URI environment variable is not set');
    }

    if (isConnected && mongoose.connection.readyState === 1) return;

    try {
        await mongoose.connect(MONGODB_URI);
        isConnected = true;
        console.log('✅ Connected to MongoDB');
    } catch (err) {
        console.error('❌ MongoDB connection error:', err);
        throw err;
    }
};

// Middleware
app.use(cors());
app.use(express.json({ limit: '10kb' }));
app.use(apiLimiter);

// Database connection middleware (for serverless)
app.use(async (req, res, next) => {
    try {
        await connectDB();
        next();
    } catch (err) {
        res.status(500).json({ success: false, message: 'Database connection error' });
    }
});

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

// For local development with Socket.IO
if (process.env.NODE_ENV !== 'production') {
    const { initializeSocket } = require('./socket');
    const { startCleanupJob } = require('./jobs/cleanup');

    const server = http.createServer(app);
    initializeSocket(server);

    const PORT = process.env.PORT || 5000;

    connectDB().then(() => {
        startCleanupJob();
        server.listen(PORT, () => {
            console.log(`🚀 Server running on port ${PORT}`);
        });
    });
}

// Export for Vercel (MUST be default export)
module.exports = app;
