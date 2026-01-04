const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);

// Socket.IO with CORS
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Store connected users
const connectedUsers = new Map();

// JWT verification middleware for Socket
io.use((socket, next) => {
  try {
    const token = socket.handshake.auth.token;

    if (!token) {
      return next(new Error('Authentication required'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.userId = decoded.userId;
    next();
  } catch (error) {
    next(new Error('Invalid token'));
  }
});

// Socket connection handler
io.on('connection', (socket) => {

  // Store user connection
  connectedUsers.set(socket.userId, socket.id);

  // Join user's personal room
  socket.join(`user:${socket.userId}`);

  // Join a chat room
  socket.on('join_chat', (joinRequestId) => {
    socket.join(`chat:${joinRequestId}`);
  });

  // Leave a chat room
  socket.on('leave_chat', (joinRequestId) => {
    socket.leave(`chat:${joinRequestId}`);
  });

  // Join ride room (for owners)
  socket.on('join_ride', (rideId) => {
    socket.join(`ride:${rideId}`);
  });

  // Typing indicator
  socket.on('typing', (data) => {
    socket.to(`chat:${data.joinRequestId}`).emit('user_typing', {
      userId: socket.userId,
      isTyping: data.isTyping
    });
  });

  socket.on('disconnect', () => {
    connectedUsers.delete(socket.userId);
  });
});

// ============================================
// HTTP API for backend to trigger events
// ============================================

// Secret key for backend-to-websocket communication
const API_SECRET = process.env.API_SECRET || 'websocket-api-secret';

// Middleware to verify API secret
const verifyApiSecret = (req, res, next) => {
  const secret = req.headers['x-api-secret'];
  if (secret !== API_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
};

// Emit new message to chat room
app.post('/emit/message', verifyApiSecret, (req, res) => {
  const { joinRequestId, message } = req.body;
  io.to(`chat:${joinRequestId}`).emit('new_message', message);
  res.json({ success: true });
});

// Emit new join request to ride owner
app.post('/emit/join-request', verifyApiSecret, (req, res) => {
  const { ownerId, rideId, joinRequest } = req.body;

  // 1. Notify owner globally (for red dot)
  if (ownerId) {
    io.to(`user:${ownerId}`).emit('new_join_request', joinRequest);
  }

  // 2. Notify ride room (optional, for real-time UI if looking at ride)
  io.to(`ride:${rideId}`).emit('new_join_request', joinRequest);

  res.json({ success: true });
});

// Emit request accepted to requester
app.post('/emit/request-accepted', verifyApiSecret, (req, res) => {
  const { userId, data } = req.body;
  io.to(`user:${userId}`).emit('request_accepted', data);
  res.json({ success: true });
});

// Emit request rejected to requester
app.post('/emit/request-rejected', verifyApiSecret, (req, res) => {
  const { userId, data } = req.body;
  io.to(`user:${userId}`).emit('request_rejected', data);
  res.json({ success: true });
});

// Emit ride filled
app.post('/emit/ride-filled', verifyApiSecret, (req, res) => {
  const { rideId } = req.body;
  io.to(`ride:${rideId}`).emit('ride_filled', { rideId });
  res.json({ success: true });
});

// Emit message edited
app.post('/emit/message-edited', verifyApiSecret, (req, res) => {
  const { joinRequestId, message } = req.body;
  io.to(`chat:${joinRequestId}`).emit('message_edited', message);
  res.json({ success: true });
});

// Emit message deleted
app.post('/emit/message-deleted', verifyApiSecret, (req, res) => {
  const { joinRequestId, messageId } = req.body;
  io.to(`chat:${joinRequestId}`).emit('message_deleted', { messageId });
  res.json({ success: true });
});

// Emit messages read (Seen status)
app.post('/emit/messages-read', verifyApiSecret, (req, res) => {
  const { joinRequestId, userId, lastRead } = req.body;
  io.to(`chat:${joinRequestId}`).emit('messages_read', { userId, lastRead });
  res.json({ success: true });
});

// Emit new ride (broadcast to everyone)
app.post('/emit/new-ride', verifyApiSecret, (req, res) => {
  const { ride } = req.body;
  io.emit('new_ride', ride); // Broadcast to "all" connected sockets
  res.json({ success: true });
});

// Emit ride cancelled (broadcast to everyone)
app.post('/emit/ride-cancelled', verifyApiSecret, (req, res) => {
  const { rideId } = req.body;
  io.emit('ride_cancelled', { rideId }); // Broadcast to "all"
  res.json({ success: true });
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    connections: connectedUsers.size,
    timestamp: new Date().toISOString()
  });
});

// Start server
const PORT = process.env.PORT || 3001;
// Keep-Alive prevention for Render (Ping every 10 minutes)
const KEEP_ALIVE_INTERVAL = 10 * 60 * 1000; // 10 minutes

setInterval(() => {
  const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http';
  const host = process.env.RENDER_EXTERNAL_HOSTNAME || `localhost:${PORT}`;
  const url = `${protocol}://${host}/health`;

  // Choose the correct module
  const client = protocol === 'https' ? require('https') : require('http');

  client.get(url, (resp) => {
    // console.log(`💓 Keep-Alive ping: ${resp.statusCode}`);
  }).on('error', (err) => {
    // console.error('Keep-Alive ping failed:', err.message);
  });
}, KEEP_ALIVE_INTERVAL);

server.listen(PORT, () => {
  console.log(`🚀 WebSocket server running on port ${PORT}`);
});
