# RideShare Backend

Node.js + Express + MongoDB API for the RideShare app.

## Setup

```bash
npm install
cp .env.example .env
# Edit .env with your configuration
npm run dev
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 5000 |
| `MONGODB_URI` | MongoDB connection string | - |
| `JWT_SECRET` | Secret for JWT tokens | - |
| `JWT_EXPIRES_IN` | Token expiration | 7d |

## API Endpoints

### Auth
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login
- `GET /auth/me` - Get current user
- `PATCH /auth/profile` - Update profile

### Rides
- `GET /rides` - List available rides
- `GET /rides/my` - My posted rides
- `POST /rides` - Create ride
- `DELETE /rides/:id` - Cancel ride

### Join Requests
- `POST /rides/:id/join` - Request to join
- `GET /rides/:id/requests` - Get requests (owner)
- `POST /join/:id/accept` - Accept request
- `GET /join/my` - My requests

### Chat
- `GET /join/:id/messages` - Get messages
- `POST /join/:id/messages` - Send message

## Deployment

Configured for Vercel. See `vercel.json`.
