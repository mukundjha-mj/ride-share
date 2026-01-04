# 🚗 RideShare

A campus ride-sharing app that connects students for shared transportation. Built with the **"controlled ambiguity window"** pattern—a social design that mirrors how people naturally coordinate rides via messaging.

## 📱 How It Works

```
Post a Ride → Others Request to Join → Private Chats → Accept One → Others Get Graceful "Ride Filled" Message
```

No rejections. No awkward silences. Just natural coordination.

## 🏗️ Project Structure

```
ride-share/
├── backend/           # Node.js + Express + MongoDB API (Vercel)
├── websocket-server/  # Separate Real-time Server (Render)
├── app/               # Flutter mobile app (Android/iOS)
└── docs/              # Documentation
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- MongoDB (local or Atlas)
- Flutter 3.10+

### 1. Backend (API)
```bash
cd backend
npm install
cp .env.example .env  # Add MongoDB URI & JWT_SECRET
npm run dev
```

### 2. WebSocket Server (Real-time)
```bash
cd websocket-server
npm install
cp .env.example .env  # Add PORT=3001 & Secrets
node index.js
```

### 3. Mobile App
```bash
cd app
flutter pub get
cp .env.example .env  # Add API & WebSocket URLs
flutter run
```

> **Note:** The app requires the `.env` file to know where the backend is. See `.env.example` for the format.

## ☁️ Deployment

- **Backend:** Deployed on **Vercel** (`https://ride-share-prod.vercel.app`)
- **WebSocket:** Deployed on **Render** (`https://rideshare-websocket.onrender.com`)
- **App:** Built as APK/IPA (configure `.env` with production URLs before building)

## 🔑 Features

- ✅ Post rides with time windows
- ✅ Request to join rides
- ✅ Private chat per request
- ✅ Real-time messaging (Socket.IO)
- ✅ Transaction-safe accept (one winner, graceful close for others)
- ✅ Profile management
- ✅ Dark theme with premium UI

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Credits

Built for campus communities who deserve better than texting "anyone going to X?"
