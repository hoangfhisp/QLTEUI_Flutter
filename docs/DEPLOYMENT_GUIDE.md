# Build & Deployment Guide

## 1. Prerequisites

Ensure your environment satisfies the following requirements:

- **Flutter SDK**: `>= 3.9.2` (Dart SDK `>= 3.9.2 < 4.0.0`)
- **Java Development Kit (JDK)**: OpenJDK 17
- **Android SDK**: API Level 34 (Android 14) with Command-line Tools and Platform Tools
- **Gradle**: Supported by Flutter Gradle plugin (wrapper included in `android/`)
- **Operating System**: Windows 10/11, macOS (for iOS builds), or Linux

---

## 2. Environment Setup

1. Copy the environment configuration template:
   ```bash
   cp .env.example .env
   ```

2. Open `.env` and fill in your gateway parameters:
   ```env
   BASE_URL=https://your-api-gateway.com/api/
   URL_SERVER=https://your-signalr-server.com/api/
   CLIENT_ID_GOOGLE=your_google_client_id.apps.googleusercontent.com
   SERVER_CLIENT_ID_GOOGLE=your_server_client_id.apps.googleusercontent.com
   ```

3. Download required Flutter packages:
   ```bash
   flutter pub get
   ```

---

## 3. Running in Development

### 3.1 Android Emulator or Physical Device
Ensure USB debugging is enabled on your physical device or launch an AVD from Android Studio:

```bash
# Check connected devices
flutter devices

# Launch development build
flutter run
```

### 3.2 Required Android Permissions
When running on child devices, grant the following permissions on first launch:
1. **Location**: Select *Allow all the time* for background tracking.
2. **Accessibility**: Open *Settings > Accessibility > Installed apps > QLTE Accessibility Service* and turn it ON.
3. **Display over other apps**: Allow drawing overlays for urgent alerts and study popups.

---

## 4. Production Build Instructions

### 4.1 Build Split-per-ABI APKs
Split APKs significantly reduce download size for target device architectures:

```bash
flutter build apk --split-per-abi --release
```
Outputs:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### 4.2 Build Android App Bundle (AAB for Google Play)
```bash
flutter build appbundle --release
```
Output:
- `build/app/outputs/bundle/release/app-release.aab`

---

## 5. Code Quality & Formatting

Run static analysis before committing code changes:

```bash
flutter analyze
```
