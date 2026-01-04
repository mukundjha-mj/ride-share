# WebSocket Server for RideShare

Standalone WebSocket server for real-time messaging. Deploy on Render for WebSocket support.

## Setup

```bash
npm install
cp .env.example .env
# Edit .env with your secrets
npm start
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `PORT` | Server port (default: 3001) |
| `JWT_SECRET` | Must match backend JWT_SECRET |
| `API_SECRET` | Secret for backend HTTP calls |

## Deploy on Render

1. Create new **Web Service** on Render
2. Connect this folder's repo
3. Set environment variables
4. Deploy!

## API Endpoints (for backend)

All endpoints require `x-api-secret` header.

| Endpoint | Description |
|----------|-------------|
| `POST /emit/message` | Send message to chat |
| `POST /emit/join-request` | Notify ride owner |
| `POST /emit/request-accepted` | Notify requester |
| `GET /health` | Health check |
