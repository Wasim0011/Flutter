# Release Build & Signing Guide — InAllCart (Customer App)

This guide explains how to configure the app for a production release: creating
a release keystore, signing the build, setting your API URL, and configuring
deep links. Complete every step before submitting to the Play Store / App Store.

---

## 1. Configure your API server URL

Open `lib/core/constants/app_constants.dart` and set your backend URL:

```dart
static const String apiBaseUrl = 'https://api.yourdomain.com';
```

Replace the placeholder `https://YOUR_SERVER_URL_HERE` with your live server.
Use an **HTTPS** URL — the app ships with cleartext (HTTP) traffic disabled.

---

## 2. Configure the Google Maps API key (Android)

Open `android/local.properties` and add your key:

```
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

`local.properties` is git-ignored and never shipped.

---

## 3. Configure deep links (optional but recommended)

Deep links use a custom URL scheme (e.g. `yourapp://product/123`) and your
website domain for App Links (e.g. `https://yourdomain.com/product/123`).

1. **Dart** — set the scheme in `lib/core/constants/app_constants.dart`:
   ```dart
   static const String appScheme = 'yourapp';
   ```

2. **Android** — set the matching values in `android/local.properties`:
   ```
   DEEP_LINK_SCHEME=yourapp
   DEEP_LINK_HOST=yourdomain.com
   ```
   These feed the `${deepLinkScheme}` / `${deepLinkHost}` placeholders in
   `AndroidManifest.xml` automatically. Defaults are `inallcart` / `example.com`.

3. **iOS** — set the scheme in `ios/Runner/Info.plist` under
   `CFBundleURLTypes > CFBundleURLSchemes` (replace `inallcart`).

The scheme in all three places must be identical.

---

## 4. Create a release keystore

Run this once (requires the JDK `keytool`, bundled with Android Studio):

```bash
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be asked for a password and certificate details. Keep the resulting
`upload-keystore.jks` file and its passwords safe — **if you lose them you
cannot update your app on the Play Store.**

---

## 5. Create `android/key.properties`

Copy the template and fill in your details:

```bash
cp android/key.properties.example android/key.properties
```

```
storePassword=<your keystore password>
keyPassword=<your key password>
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile` is resolved relative to the `android/` folder. Place your `.jks`
there, or use an absolute path.

> `key.properties`, `*.jks`, and `*.keystore` are already git-ignored. Never
> commit them.

---

## 6. Build the release

```bash
flutter build appbundle   # Android App Bundle for the Play Store
flutter build apk         # APK
flutter build ios         # iOS (then archive in Xcode)
```

When `android/key.properties` exists, the release build is signed with your
keystore automatically. If it is absent, the build falls back to debug keys so
`flutter run --release` still works during evaluation — **debug-signed builds
cannot be published to the Play Store.**

---

## Verify before submission

- [ ] `apiBaseUrl` points to your HTTPS production server
- [ ] `android/key.properties` exists and the release build is signed with it
- [ ] Deep link scheme/host updated (Dart + Android + iOS)
- [ ] `google-services.json` / `GoogleService-Info.plist` replaced with your own
      Firebase project files
- [ ] App display name and icons updated to your brand
