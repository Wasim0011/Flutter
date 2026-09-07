# InAllCart User Mobile Application

The customer-facing mobile application for the InAllCart multi-vendor delivery platform, built with Flutter.

## 🚀 Setup & Configuration

### 1. Configure API Base URL
Open `lib/core/constants/app_constants.dart` and update `apiBaseUrl` with your domain:
```dart
static const String apiBaseUrl = 'https://your-domain.com';
```

### 2. Configure Firebase Setup
1. Install [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
2. Run the configuration command in the project root:
   ```bash
   flutterfire configure
   ```
3. Download your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from the Firebase Console and place them in:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### 3. Change Package Name / Bundle Identifier
- **Android**: Update `applicationId` in `android/app/build.gradle.kts` and `namespace` in `android/app/build.gradle.kts`.
- **iOS**: Update Bundle Identifier in Xcode (`ios/Runner.xcworkspace`).

### 4. Build & Run
```bash
flutter pub get
flutter run
```

