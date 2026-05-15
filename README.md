# SmartQueue — Virtual Queue Management

A minimal Flutter mobile app that replaces physical waiting lines with a
digital queue: users take a token, watch their position in real time, and
get an in-app alert when their turn is near.

Built for *Group Alpha* (Md Akram Hossain — 25, Towfiq Hasan Nime — 26).

## Features (minimal demo scope)

- Take a digital token (auto-incremented number, persisted in SQLite).
- Live queue view with all active tokens, updates every 2 seconds.
- "You're next" / "It's your turn" snackbar alert when position ≤ 1.
- "Call Next" button advances the queue (single-device admin control).
- "Clear queue" to reset between demos.
- All data stored locally — no network required.

## Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (stable 3.24.3) |
| Language | Dart 3 |
| Persistence | SQLite via `sqflite` |
| UI | Material 3 |
| Min Android | API 21 (Android 5.0) |

## Project layout

```
smartqueue/
├── lib/
│   ├── main.dart              # App entrypoint
│   ├── db/queue_db.dart       # SQLite helper (singleton)
│   ├── models/token.dart      # QueueToken data class
│   └── screens/
│       ├── home_screen.dart   # Landing — "Take a Token" / "View Queue"
│       └── queue_screen.dart  # Live queue + Call Next + alerts
├── pubspec.yaml
├── analysis_options.yaml
└── .github/workflows/build.yml  # Cloud build pipeline (produces APK)
```

The `android/` folder is intentionally **not** checked in — CI regenerates
it with `flutter create` on every build. This keeps the repo tiny (~20 KB)
and avoids platform-folder drift.

## Building the APK — cloud build (no local Flutter needed)

1. Push this folder to a new GitHub repository.
2. GitHub Actions automatically runs `.github/workflows/build.yml`.
3. Wait ~5 minutes for the build to finish.
4. Open the run from the **Actions** tab → scroll to **Artifacts** →
   download **`smartqueue-release-apk`**.
5. Unzip → install `smartqueue-release.apk` on any Android phone
   (you may need to enable "Install from unknown sources").

### Trigger manually

The workflow also exposes a **Run workflow** button (workflow_dispatch),
so you can rebuild without committing.

## Building locally (optional)

If you ever install the Flutter SDK locally, the standard commands work:

```bash
flutter pub get
flutter create . --project-name smartqueue --org com.groupalpha --platforms=android
flutter run                # debug on a connected device/emulator
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

## How to demo

1. Launch the app → "Take a Token" → you get token #1, position 0
   (immediately being served, since the queue was empty).
2. Tap back to home → "Take a Token" again → token #2 issued.
   Repeat to fill the queue.
3. On any token screen, hit **Call Next** to advance the queue — watch
   positions decrease, and the orange "It's your turn" snackbar fires
   when your token becomes the active one.
4. Use the trash icon in the app bar to clear the queue between demos.

## Notes on the proposal mapping

| Proposal element | Implementation |
|------------------|----------------|
| Digital token instead of physical queue | `Take a Token` issues a numbered token |
| Real-time queue position | Polled every 2 s, redrawn live |
| Notification when turn is near | In-app snackbar at position ≤ 1 |
| Admin queue control | "Call Next" / "Clear" buttons (no separate role for minimal demo) |
| Multiple service centers | Out of scope for minimal demo (single queue) |

The signed release APK is built with debug keys (Flutter default).
That's fine for installing on phones / demoing, but it is **not** suitable
for Play Store submission as-is.
