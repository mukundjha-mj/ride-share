# RideShare Mobile App

Flutter mobile app for Android and iOS.

## Setup

```bash
flutter pub get
flutter run
```

## Configuration

Update `lib/config/api_config.dart` with your backend URL:

```dart
static const String baseUrl = 'https://your-backend.vercel.app';
```

## Project Structure

```
lib/
├── config/          # App configuration
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # API services
└── widgets/         # Reusable widgets
```

## Build

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

## Features

- 🔐 JWT Authentication
- 🚗 Browse & post rides
- 💬 Real-time chat (Socket.IO)
- 👤 Profile management
- 🌙 Dark theme
