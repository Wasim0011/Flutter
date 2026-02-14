# ✨ Gossip — Flutter Social Matching App

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-integrated-yellow?logo=firebase)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey)

> **Gossip** is a modern Flutter-powered social application that combines chat, matchmaking, personal thoughts, and real-time news — all personalized based on user-selected topics and moods (vibes). Built with clean architecture, Firebase integration, and a scalable UI component structure.

## 🧭 Table of Contents
- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Contributing](#contributing)
- [License](#license)

## 🌟 Features

### 🔐 Authentication
- Email & password-based login/signup
- Email verification
- Avatar, username, and vibe selection
- Terms and conditions enforcement

### 💬 Real-Time Chat
- Topic-based and vibe-based chat matchmaking
- Individual and group chat support
- Recent chat and messaging UI

### 🧠 Thoughts Sharing
- Post thoughts and view others’ expressions
- Comment and engage in meaningful conversations
- Image preview for posts

### 📰 News Integration
- Trending news from Firestore/external API
- Clean and responsive news tiles

### 👤 Profile Management
- Edit bio, username, and selected topics
- View other users' profiles
- Reporting and reviewing system
- Post management for users

### 🔔 Notifications
- Firebase Cloud Messaging integration
- In-app notification handling and display

## 📸 Screenshots
> *(Add screenshots here when available — home screen, chat, profile, thoughts, etc.)*

## 📁 Folder Structure
```
lib/
├── auth/
│   ├── components/
│   ├── register/
├── bottomNavigattionScreens/
├── chats/
├── components/
├── news/
├── notifications/
├── profile/
├── themes/
├── thoughts/
├── firebase_options.dart
├── home_page.dart
└── main.dart
```

## 🛠️ Tech Stack
| Category       | Technology         |
|----------------|--------------------|
| Frontend       | Flutter (Dart)     |
| Backend (BaaS) | Firebase (Auth, Firestore, Messaging) |
| State Mgmt     | Provider  |
| UI/UX          | Custom Widgets + Material Design |
| Notifications  | FCM (Push Notifications) |

## 🚀 Getting Started

### 1. Clone the Repo
```bash
git clone https://github.com/your-username/vibeconnect.git
cd vibeconnect
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
- Add your Firebase project configuration:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- Ensure `firebase_options.dart` is generated using:
```bash
flutterfire configure
```

### 4. Run the App
```bash
flutter run
```

## ⚙️ Scripts & Dev Commands
```bash
flutter run -d android
flutter run -d ios
flutter format .
flutter analyze
```

## 🤝 Contributing
Contributions, issues, and feature requests are welcome!

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

> “Build vibes. Build connections.” — *Gossip*
