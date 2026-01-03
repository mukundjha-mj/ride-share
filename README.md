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
├── backend/     # Node.js + Express + MongoDB API
├── app/         # Flutter mobile app (Android/iOS)
└── docs/        # Documentation (coming soon)
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- MongoDB (local or Atlas)
- Flutter 3.10+

### Backend
```bash
cd backend
npm install
cp .env.example .env  # Configure your environment
npm run dev
```

### Mobile App
```bash
cd app
flutter pub get
flutter run
```

> Update `app/lib/config/api_config.dart` with your backend URL.

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

### Areas We Need Help
- [ ] iOS testing
- [ ] Localization (Hindi, Tamil, etc.)
- [ ] Push notifications
- [ ] Campus-specific features

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Credits

Built for campus communities who deserve better than texting "anyone going to X?"
