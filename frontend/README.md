# RideShare Frontend

Modern React JS frontend for the RideShare application with shadcn-inspired UI and Bento grid layout.

## Features

- 🔐 **Authentication**: Login, Register, Profile management
- 🚗 **Ride Management**: Browse, create, and cancel rides
- 💬 **Real-time Chat**: Socket.IO powered messaging
- 📱 **Responsive Design**: Mobile-first, works on all devices
- 🌙 **Dark Mode**: Toggle between light and dark themes
- 🔔 **Notifications**: Unread message indicators
- ✨ **Modern UI**: Glass effects, gradients, Bento grid layout

## Tech Stack

- React 19 + Vite
- Tailwind CSS v4
- Radix UI primitives
- Lucide React icons
- React Router v7
- Socket.IO Client
- Axios
- date-fns
- react-hot-toast

## Setup

1. Copy environment file:
   ```bash
   cp .env.example .env
   ```

2. **Update `.env` with your API URLs** (required):
   ```
   VITE_API_URL=<your-backend-api-url>
   VITE_WS_URL=<your-websocket-server-url>
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

4. Start development server:
   ```bash
   npm run dev
   ```

## Project Structure

```
src/
├── components/
│   ├── ui/             # shadcn-style UI components
│   ├── layout/         # Layout components
│   └── rides/          # Ride-specific components
├── context/            # React Context providers
├── lib/                # Utilities (cn helper)
├── pages/              # Route pages
├── services/           # API & Socket services
├── index.css           # Tailwind + custom styles
├── App.jsx             # Main app with routing
└── main.jsx            # Entry point
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `VITE_API_URL` | Backend API URL | ✅ Yes |
| `VITE_WS_URL` | WebSocket server URL | ✅ Yes |

> ⚠️ **Note**: The app requires both environment variables to be set. Copy `.env.example` to `.env` and fill in your URLs.
