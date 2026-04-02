# Velo - Smart Music Player (Flutter)

Velo is a modern Flutter music player that blends high-performance local playback with a massive online streaming library powered by Jamendo.  
It combines legal Creative Commons downloads, real-time lyrics, smart playlist generation, and a production-grade admin control layer.

## Why This Project Matters

- Built as a real-world, scalable app architecture (not a tutorial starter).
- Blends offline-first music experience with cloud-connected controls.
- Demonstrates end-to-end product thinking: UX, state management, push notifications, remote config, admin tools, and reliability.

## Core Features

- High-fidelity music streaming of 600,000+ tracks via Jamendo Music.
- Legal MP3 downloads with real-time progress tracking and public folder storage.
- Smart Lyrics integration featuring high-quality backdrop blur and intelligent metadata filtering.
- Dynamic "Made for You" recommendations (Personalized Daily Mix, Discover Weekly style flows).
- Horizontally scrollable Quick Filters for instant genre-based discovery.
- Advanced queue management and mini/full-screen player with integrated lyrics view.
- Offline-first resilience with a dedicated "No Internet" handling and offline status banners.
- Responsive layouts for mobile and tablet/landscape.
- Radio entry flow and settings/privacy/terms/feedback sections.
- In-app promoted apps experience with analytics hooks.

## Admin & Cloud Features

- Admin authentication flow (login, signup, forgot password, email verification).
- Admin dashboard for:
  - user management,
  - FCM token monitoring and cleanup,
  - app settings and remote toggles,
  - promoted apps management and analytics,
  - production notification sending.
- Firebase Remote Config + Firestore based feature flags.
- Contact-developer / giftbox style runtime-configurable experiences.

## Tech Stack

### Framework & Language
- Flutter
- Dart (SDK >= 3.5.4)

### State Management & Routing
- GetX (`get`)

### Backend / Cloud
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Firebase Messaging (FCM)
- Firebase Remote Config
- Firebase Analytics
- Firebase Crashlytics

### Audio & Media
- `just_audio` & `audio_service` (Media session control)
- `Jamendo Music API` (High-quality CC streaming)
- `Genius API` (Real-time dynamic lyrics)
- `on_audio_query` (Local library indexing)
- `audio_waveforms` (Modern player visualization)
- `dio` (Robust file downloads with progress monitoring)

### Utilities & UX
- `shared_preferences`
- `flutter_secure_storage`
- `connectivity_plus`
- `cached_network_image`
- `awesome_notifications`
- `lottie`
- `permission_handler`
- `file_picker`
- `url_launcher`

## Architecture Notes

- Feature-first folder structure under `lib/features/`.
- Shared modules and services under `lib/core/`.
- Route registry via GetX pages in `lib/routhing/`.
- Service-driven design for audio, notifications, FCM, and remote config.
- Crash and runtime observability through Crashlytics and debug tracing.

## Platforms

This project contains Flutter targets for:
- Android
- iOS

## Local Setup

### 1) Prerequisites
- Flutter SDK installed
- Dart SDK compatible with `pubspec.yaml`
- Firebase project (for Auth, Firestore, Messaging, Remote Config, Crashlytics)

### 2) Clone & install dependencies

```bash
git clone https://github.com/kooo12/velo_music
cd velo
flutter pub get
```

### 3) Configure environment variables

Create a `.env` file at project root and add your Firebase values:

```env
FIREBASE_ANDROID_API_KEY=...
FIREBASE_ANDROID_APP_ID=...
FIREBASE_ANDROID_MESSAGING_SENDER_ID=...
FIREBASE_ANDROID_PROJECT_ID=...
FIREBASE_ANDROID_STORAGE_BUCKET=...

FIREBASE_IOS_API_KEY=...
FIREBASE_IOS_APP_ID=...
FIREBASE_IOS_MESSAGING_SENDER_ID=...
FIREBASE_IOS_PROJECT_ID=...
FIREBASE_IOS_STORAGE_BUCKET=...
FIREBASE_IOS_BUNDLE_ID=...
```

### 4) Firebase platform config files

Add platform files as required:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 5) Run the app

```bash
flutter run
```

## Suggested Demo Scenarios (Project Showcase)

- Permission flow -> load local songs -> play/shuffle queue.
- Create/edit playlist -> add songs -> open full-screen player.
- Explore personalized mixes from home widgets.
- Open admin flow and demonstrate remote-config/notification controls.
- Show FCM token management and cleanup stats.

## Testing

Run tests with:

```bash
flutter test
```

## License

This project is licensed under the Apache License 2.0.  
See the `LICENSE` file for details.

## Additional Documentation

- Contribution guide: `CONTRIBUTING.md`
- Security policy: `SECURITY.md`

## Repository Highlights for Recruiters / Clients

- Cross-platform product engineering with Flutter.
- Production integrations (Firebase, notifications, crash monitoring).
- Clean modular structure with route + binding discipline.
- Strong focus on UX polish and performance-oriented music interactions.

## Disclaimer

Velo is a personal/portfolio project for product engineering and architecture showcase.  
If you plan to publish it publicly, ensure proper licensing for any media assets and verify all production credentials/security rules.
