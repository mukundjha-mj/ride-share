# Contributing to RideShare

Thank you for your interest in contributing! This guide will help you get started.

## 🏗️ Project Structure

- **`backend/`** - Node.js + Express + MongoDB API
- **`websocket-server/`** - Standalone Socket.IO Server for real-time events
- **`app/`** - Flutter mobile application

## 🚀 Development Setup

### 1. Backend
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your MongoDB URI
npm run dev
```

### 2. WebSocket Server
```bash
cd websocket-server
npm install
cp .env.example .env
node index.js
```

### 3. Flutter App
```bash
cd app
flutter pub get
cp .env.example .env
# Edit app/.env with your local backend URLs (e.g. http://192.168.1.5:5000)
flutter run
```

## 📝 How to Contribute

### 1. Fork & Clone
```bash
git clone https://github.com/YOUR_USERNAME/ride-share.git
cd ride-share
```

### 2. Create a Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 3. Make Changes
- Write clean, readable code
- Add comments for complex logic
- Test your changes locally

### 4. Commit
```bash
git add .
git commit -m "feat: add new feature"
# or
git commit -m "fix: resolve issue with X"
```

Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Adding tests

### 5. Push & Create PR
```bash
git push origin feature/your-feature-name
```

Then open a Pull Request on GitHub.

## ✅ What We're Looking For

- Bug fixes
- New features (discuss in an issue first)
- Documentation improvements
- UI/UX enhancements
- Performance optimizations
- Tests

## ⚠️ Guidelines

- **Don't break existing functionality** - Test before submitting
- **One feature per PR** - Keep PRs focused
- **Discuss big changes first** - Open an issue before major refactors
- **Be respectful** - We're all here to learn and build

## 🐛 Reporting Bugs

Open an issue with:
1. What you expected to happen
2. What actually happened
3. Steps to reproduce
4. Screenshots (if applicable)

## 💡 Suggesting Features

Open an issue with:
1. Problem you're trying to solve
2. Your proposed solution
3. Any alternatives you considered

## 🙏 Thank You!

Every contribution matters. Whether it's fixing a typo or adding a major feature, we appreciate your help!
