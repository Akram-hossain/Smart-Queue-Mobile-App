# SemesterMate — Student Productivity & Academic Management

A premium, production-style Flutter app that helps university students stay on
top of CT/lab/viva/final exams, assignments, attendance, semester fees and
GPA/CGPA — all backed by Supabase with Row Level Security.

Built as a 6th-semester Mobile Application Development project.

## Features

- **Authentication** — email/password via Supabase Auth, persistent sessions,
  registration capturing department / semester / university.
- **Dashboard** — greeting, upcoming exams (CT/lab/viva), assignment reminders,
  fee-due warnings, attendance summary, GPA summary, weekly productivity chart,
  motivational quote, quick actions.
- **Tasks** — full CRUD over CT exams, lab exams, vivas, assignments and finals
  with priorities, status, search, type filters, list view and calendar view.
- **Attendance** — per-subject tracking with auto-percentage, <75% warnings,
  analytics chart.
- **Semester fees** — total/paid/due tracking, deadline reminders, progress
  indicator, payment history.
- **GPA & CGPA** — add courses, select grades, auto-calculate semester GPA,
  estimate CGPA, analytics chart.
- **Local notifications** — schedulable reminders for exams, assignments and
  fee deadlines.
- **Profile & settings** — academic summary, light/dark mode, notification
  toggle, logout.

## Tech stack

| Layer        | Choice                                            |
|--------------|---------------------------------------------------|
| Framework    | Flutter (stable 3.24.3) — Material 3              |
| Language     | Dart 3 with null safety                           |
| State        | Riverpod (`flutter_riverpod`)                     |
| Routing      | `go_router` with auth guard                       |
| Backend      | Supabase (Auth + PostgreSQL + RLS)                |
| Local DB     | `shared_preferences` (settings only)              |
| Charts       | `fl_chart`                                        |
| Calendar     | `table_calendar`                                  |
| Notifications| `flutter_local_notifications` + `timezone`        |
| Typography   | `google_fonts` (Inter)                            |
| Polish       | `shimmer` skeletons                               |

## Project layout

```
smartqueue/                      # repo folder name (legacy — package is "semestermate")
├── lib/
│   ├── main.dart
│   ├── core/                    # env, theme, constants
│   ├── models/                  # data classes
│   ├── services/                # supabase + notification services
│   ├── repositories/            # data access layer
│   ├── providers/               # Riverpod state
│   ├── routes/                  # go_router config
│   ├── widgets/                 # reusable UI
│   ├── utils/                   # validators, date/grade helpers
│   └── screens/                 # one folder per feature
├── supabase/
│   └── schema.sql               # tables + RLS policies (paste into SQL Editor)
├── .github/workflows/build.yml  # cloud APK build
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

The `android/` folder is **not committed** — CI regenerates it on every build,
then patches `AndroidManifest.xml` for notification permissions. This keeps the
repo tiny.

## Supabase setup (one-time)

1. Create a free Supabase project at https://app.supabase.com.
2. Open **Project settings → API** and copy:
   - **Project URL** (e.g. `https://abcd.supabase.co`)
   - **anon public key**
3. Open **SQL Editor → New query**, paste the entire contents of
   [`supabase/schema.sql`](supabase/schema.sql), and run it.
   This creates the `profiles`, `tasks`, `attendance`, `semester_fees`,
   `gpa_records` tables, enables RLS, and installs per-user policies.
4. In **Authentication → Providers** make sure **Email** is enabled. For demo
   you may want to turn **"Confirm email"** OFF so test sign-ups can log in
   without clicking a confirmation link.

## GitHub secrets (so CI bakes the URL/key into the APK)

In your GitHub repo → **Settings → Secrets and variables → Actions → New
repository secret** add:

| Name                | Value                          |
|---------------------|--------------------------------|
| `SUPABASE_URL`      | your project URL               |
| `SUPABASE_ANON_KEY` | your anon public key           |

The workflow passes them to `flutter build apk` via `--dart-define`, so the
keys never appear in committed code.

## Cloud build (no local Flutter required)

1. Push to GitHub (or use the **Run workflow** button in the Actions tab).
2. Workflow `Build APK` runs `flutter create .`, installs deps, builds release.
3. Download the `semestermate-release-apk` artifact from the run page,
   unzip and install `semestermate-release.apk` on any Android phone
   (enable "Install from unknown sources" if prompted).

## Local build (optional)

If you install Flutter 3.24.3 locally:

```bash
flutter pub get
flutter create . --project-name semestermate --org com.groupalpha --platforms=android --empty
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

The APK lands at `build/app/outputs/flutter-apk/app-release.apk`.

## Notes

- **Notifications:** Android 13+ requires runtime POST_NOTIFICATIONS permission
  — the app requests it on first launch.
- **Release signing:** the APK is signed with Flutter's debug key. That's fine
  for sideloading / demos. For Play Store you'd need a real keystore.
- **Empty Supabase config:** if `SUPABASE_URL` is missing at build time the app
  shows an in-app "Supabase not configured" warning instead of crashing.
