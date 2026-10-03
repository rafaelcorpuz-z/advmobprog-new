# MobProg Activity App

A Flutter mobile app for browsing products, managing a shopping cart, handling user authentication, and using Firebase-backed features such as chat and account management.

## Overview

This project combines:

- Flutter UI screens for home, cart, profile, settings, sign-in, sign-up, splash, and chat
- Firebase Authentication for real user sessions
- Firestore integration for app data
- DummyJSON-based authentication fallback
- Theme switching and persistent cart state
- Shared preferences for session and user settings

## Features

- Product browsing and store UI
- Shopping cart management with Provider state
- User sign-in and sign-up flows
- Firebase and DummyJSON login support
- Profile management and password updates
- Theme toggle for light/dark mode
- Chat screen and messaging flow
- Firebase configuration using FlutterFire

## Tech Stack

- Flutter 3.x
- Dart 3.x
- Firebase Core / Auth
- Cloud Firestore
- Provider for state management
- SharedPreferences for local persistence
- dotenv for environment configuration

## Project Structure

```text
lib/
  main.dart
  constants.dart
  firebase_options.dart
  models/
  providers/
  screens/
  services/
  utils/
  widgets/
android/
assets/
web/
windows/
ios/
macos/
linux/
```

## Prerequisites

Before running the app, install:

- Flutter SDK
- Android Studio or Android SDK
- Android command-line tools
- Firebase CLI (if regenerating Firebase config)

## Setup

1. Clone the repository:

```bash
git clone <repository-url>
cd advmobprog-new
```

2. Install dependencies:

```bash
flutter pub get
```

3. Ensure Firebase is configured:

- `android/app/google-services.json` should be present
- `lib/firebase_options.dart` should exist
- if not, run:

```bash
flutterfire configure
```

4. Confirm the environment file exists if your app depends on it:

```text
assets/.env
```

5. Start the app:

```bash
flutter run
```

## Android build notes

This project was recently updated to address Gradle resolution issues on Windows. If you see a build error related to plugin resolution, make sure:

- Android SDK is installed and accepted
- Java/Gradle dependencies are available
- Developer Mode is enabled on Windows for symlink support
- the plugin repository configuration in `android/settings.gradle.kts` is present

### Enable Developer Mode on Windows

This is required for Flutter to create symlinks during Android builds on some Windows systems.

```powershell
start ms-settings:developers
```

Then enable Developer Mode.

### Common Gradle troubleshooting

```powershell
flutter doctor
flutter clean
flutter pub get
flutter build apk --debug
```

If the build still fails on Gradle plugin resolution, confirm the project uses a compatible Kotlin Gradle plugin version and that the Gradle plugin portal repository is configured in:

```text
android/settings.gradle.kts
```

## Authentication flow

The app supports both:

- Firebase Authentication
- DummyJSON authentication

The login type is tracked through the app so it can decide which backend to use for profile and session-related actions.

## Notes

This project is intended as a mobile app exercise in Flutter app structure, authentication flows, state management, and Firebase integration.

## License

This project is for educational use.
