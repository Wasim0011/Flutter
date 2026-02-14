#  Flutter
A modern Flutter-based mobile application utilizing the latest mobile development technologies and tools for building responsive cross-platform applications.
## 📋 Prerequisites
- Flutter SDK (^3.29.2)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)
## 🛠️ Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```
## 📁 Project Structure
```
flutter_app/
├── android/            # Android-specific configuration
├── ios/                # iOS-specific configuration
├── lib/
│   ├── core/           # Core utilities and services
│   │   └── utils/      # Utility classes
│   ├── presentation/   # UI screens and widgets
│   │   └── splash_screen/ # Splash screen implementation
│   ├── routes/         # Application routing
│   ├── theme/          # Theme configuration
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Application entry point
├── assets/             # Static assets (images, fonts, etc.)
├── pubspec.yaml        # Project dependencies and configuration
└── README.md           # Project documentation
```
## 🧩 Adding Routes
To add new routes to the application, update the `lib/routes/app_routes.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:package_name/presentation/home_screen/home_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // Add more routes as needed
  }
}
```
## 🎨 Theming

This project includes a comprehensive theming system with both light and dark themes:

```dart
// Access the current theme
ThemeData get theme => ThemeHelper().themeData();

// Use colors
color: theme.colorScheme.primary,
```

## 📱 Responsive Design
The app is built with responsive design using the SizeUtils:

```dart
// Example of responsive sizing
Container(
  width: 50.h,
  height: 20.h,
  child: Text('Responsive Container'),
)
```
## 📦 Deployment
Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## 🙏 Acknowledgments
- Built with [Rocket.new](https://rocket.new)
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ on Rocket.new

