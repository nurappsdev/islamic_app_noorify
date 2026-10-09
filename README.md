# Tuhfatul Muslim

Tuhfatul Muslim is a Flutter Islamic companion application. It combines daily
prayer-oriented content with Qur'an and Hadith reading, learning and quizzes,
zikr and amal tracking, alarms, notifications, and account features.

> This document is a code-based inventory of the current repository. It
> documents route wiring and implementations found in source; it does not
> treat a folder, route constant, or visual design as proof of completion.

## Contents

- [Application purpose](#application-purpose)
- [Key features summary](#key-features-summary)
- [Complete feature and module breakdown](#complete-feature-and-module-breakdown)
- [Home dashboard features](#home-dashboard-features)
- [Qur'an module and subfeatures](#quran-module-and-subfeatures)
- [Hadith module and subfeatures](#hadith-module-and-subfeatures)
- [Quiz module and subfeatures](#quiz-module-and-subfeatures)
- [Zikr and Islamic activities](#zikr-and-islamic-activities)
- [Prayer times, calendar and Qiblah](#prayer-times-calendar-and-qiblah)
- [Leaderboard, points and badges](#leaderboard-points-and-badges)
- [Alarm and notification systems](#alarm-and-notification-systems)
- [Authentication, profile and settings](#authentication-profile-and-settings)
- [Complete navigation structure](#complete-navigation-structure)
- [Technical architecture](#technical-architecture)
- [Project folder structure](#project-folder-structure)
- [State management and data flow](#state-management-and-data-flow)
- [APIs, Firebase and local databases](#apis-firebase-and-local-databases)
- [Offline and background functionality](#offline-and-background-functionality)
- [Localization and theme support](#localization-and-theme-support)
- [Permissions and platform configuration](#permissions-and-platform-configuration)
- [App setup and build instructions](#app-setup-and-build-instructions)
- [Feature implementation status](#feature-implementation-status)
- [Known limitations and upcoming features](#known-limitations-and-upcoming-features)

## Application purpose

The app helps users organise Islamic practice: see daily information, read or
listen to Islamic content, make plans, track activity, practise through
quizzes, manage reminders, and view personal/ranking progress. It supports a
guest path for browsing and account-backed paths for protected data.

## Key features summary

| Area | Implemented client capability |
| --- | --- |
| Home | Prayer/date cards, current-prayer progress, location label, amal progress, shortcuts and notifications. |
| Qur'an | Surah/Para reading, tafsir, audio, offline/local content, bookmarks, history, playlists, plans and dashboard. |
| Hadith | Library, e-books, readers, saved folders, plans, reading records and dashboard. |
| Quiz & learning | Categories, questions, results/reviews, articles/tests, planner and dashboard. |
| Zikr & amal | Counters, custom zikr, planning, stats screens and daily amal tracking. |
| Platform | Firebase, REST networking, GPS/geocoding, alarms, notifications, audio, Hive, SQLite and preferences. |

## Complete feature and module breakdown

There are **19 feature packages** under `lib/features`.

| Package | Source-backed scope | Status |
| --- | --- | --- |
| `alarm` | Alarm list/create/edit, bulk settings, ringing, snooze/stop and ringtones. | Implemented; must be device tested. |
| `amol_tracking` | Daily amal tracking and dashboard. | Implemented client flow. |
| `asma_husna` | Intro, 99-name list and detail. | Implemented. |
| `auth` | Login, registration, OTP/verification, reset and REST/Firebase services. | Implemented; one social UI path is disabled. |
| `dashboard` | Quiz dashboard package. | Implemented within Quiz. |
| `dua` | Intro, dashboard, categories, reader and saved screens. | Routes exist; Home entry is disabled. |
| `hadith` | Library, e-books, readers, saved, plans, history and dashboard. | Implemented; content/backend dependent. |
| `home` | Main dashboard, prayer/time/location state and prayer screen. | Implemented; see timing limitation. |
| `leaderboard` | Rankings and user detail. | Implemented; login/backend dependent. |
| `learning` | Articles, article detail, test and result. | Implemented in Quiz learning flow. |
| `legal` | About, privacy and terms documents. | Implemented. |
| `notifications` | Notification list and notification routing. | Detail content is incomplete. |
| `planner` | Quiz plans, details, creation and planned-quiz flow. | Implemented; authenticated backend flow. |
| `profile` | Profile, editing, settings, language, password, account deletion. | Implemented; family section is disabled in Profile UI. |
| `qiblah_compass` | Sensor compass with optional bearing. | Implemented; hardware dependent. |
| `quiz` | Categories, questions, completion, history and review. | Implemented; backend dependent. |
| `quran` | Reading, audio, local content, plans, saved/history and dashboard. | Implemented; page browsing is incomplete. |
| `splash` | Startup routing. | Implemented. |
| `zikr` | Counter, custom sets, planner, dashboard and stats. | Implemented; stats tab is hidden. |

## Home dashboard features

`HomeScreen` is the main post-login and guest destination. Its widgets and
state provide:

- profile and notification entry points, refresh and notification-badge state;
- Gregorian, Hijri and Bangla date presentation;
- current/next prayer progress, sunrise/sunset, Sehri/Iftar-related and
  prohibited-time presentation;
- daily amal cards for Qur'an, Hadith, Zikr, quiz, Nafl, Sunnah and Witr;
- feature shortcuts, cards and navigation to supported feature flows;
- prayer-time and Qiblah entry points; and
- device location presentation via `PrayerLocationScope` /
  `PrayerLocationText`.

The location service uses `geolocator` and `geocoding`, handles disabled
services and permission states, refreshes on lifecycle changes/movement, and
renders **district/city, country**. It changes native geocoding locale between
`en_US` and `bn_BD`; no fixed display location is used as a fallback.

### Home navigation

| Tab | Destination | Access |
| --- | --- | --- |
| Home | Main dashboard | Guest or signed in. |
| Qur'an | Surah list with offline/last-read BLoCs | Guest or signed in. |
| Hadith | First-visit intro, then library | Guest or signed in. |
| Leaderboard | Leaderboard screen | Explicit login gate. |

### Prayer-time accuracy limitation

The location **label** is dynamic, but the inspected
`PrayerTimeApiService` requests timings with fixed city/country values.
Therefore dynamic, worldwide *calculated prayer-time accuracy* is not proven
by the current implementation. It should be made coordinate-based and
tested before it is presented as global GPS prayer timing.

## Qur'an module and subfeatures

The first Qur'an visit displays an intro; later entries go directly to the
Surah list. The module includes the following wired screens and flows:

| Area | Actual behaviour |
| --- | --- |
| Browse/read | Surah list, full Surah, Surah detail/ayah, Para detail, verse reader and reading views. |
| Reference | Tafsir route from the reader. |
| Resume/save | Local last-read position, bookmarks and reading-history screens. |
| Audio | Reciter/playback/download BLoCs and a dedicated audio-player screen using background audio infrastructure. |
| Offline | Bundled Qur'an resources plus local Qur'an storage and an Offline Qur'an BLoC. |
| Saved | Local bookmarks; server-backed playlists with create/delete/pagination/detail. |
| Plans | Create/edit/delete/enrol plans, active/completed lists, plan detail and plan ayahs. |
| Dashboard | Daily/weekly/monthly reading data, charts, goals, continue-reading and optional competitor comparison. |

The persistent Qur'an shell uses an `IndexedStack`:

| Tab | State |
| --- | --- |
| Home | Browse/read flow. |
| Learn | Explicit `ComingSoonScreen`. |
| Saved | Bookmarks and playlists. |
| Plan | Reading plans. |
| Dashboard | Reading analytics/history. |

The bundled text says page numbers can be shown while reading but page-number
browsing is coming soon. A download sheet also has a TODO for a versioned
Tajweed content URL. Neither is documented here as complete functionality.

## Hadith module and subfeatures

Hadith likewise has a first-open intro followed by its library. The library
loads remote collections, e-books and last-read information through separate
BLoCs. From there the user can navigate through library list, category,
subcategory, detail and e-book routes.

The code includes an online Hadith detail reader, downloaded/local book reader,
saved-reader, PDF/e-book reader (`pdfx`), reading timer/activity records and
a history screen. Some catalog entries deliberately report “coming soon” when
content is not available.

| Bottom tab | Functionality | Access |
| --- | --- | --- |
| Library | Collection/e-book shelves, last read and see-all routes. | Normal entry. |
| Planner | Active/completed plans; create, edit, delete, complete and begin. | Login required. |
| Saved | Local folders, search, favourites/quick bookmarks and saved payloads. | Normal entry. |
| Dashboard | Daily/weekly/monthly charts, records and optional comparison. | Login required. |

The planner resolves its plan's public book/category reader because the
plan-hadith endpoint does not provide complete Hadith bodies. That is an
intentional implementation detail, not an absent reader route.

## Quiz module and subfeatures

`QuizShell` preserves four tabs with an `IndexedStack`:

| Tab | Main feature | Nested flows |
| --- | --- | --- |
| Home | Categories and daily status | Quiz list, question, completion, completed history, attempt review. |
| Learn | Learning articles | Articles, article detail, learning test and result. |
| Planner | Quiz plans | Planner, create/detail, planned quiz and result; login required. |
| Dashboard | Quiz activity | Dashboard/comparison and recent attempt data; login required. |

Question/result/review screens are wired. Scores, plans and dashboard facts
come from REST services, so their production data and authorization need
backend verification.

## Zikr and Islamic activities

### Zikr and Tasbih

Zikr provides an intro, dashboard, all-zikr list, individual set, counter,
custom-zikr form, planner, plan create/detail and stats screen. The counter
uses vibration support where available. Zikr, custom zikr and planner stores
have local Hive support.

The Zikr bottom bar currently contains **Home** and **Planner**. The stats
route/screen is retained but its navigation item is intentionally hidden.

### Amal, Salah and voluntary activity

Amal tracking has both a tracking screen and dashboard. Home cards represent
Qur'an, Hadith, Zikr, quiz, Nafl, Sunnah and Witr activity. Exact points and
completion rules depend on the response provided by the app backend.

### 99 Names of Allah

Asmaul Husna has an intro, list and name-detail experience. Its route wires an
`AsmaHusnaBloc` to remote and local data sources, allowing cached/local data
to supplement the network source.

### Dua

Routes exist for intro, dashboard, all categories, featured, group, all-Dua,
reader and saved screens. Its bottom navigation wires Home and Saved; Planner
is visible but intentionally non-interactive because a planner screen is not
implemented. The Home grid currently shows a coming-soon dialog for Dua, so
this feature is partially exposed rather than a normal Home shortcut.

## Prayer times, calendar and Qiblah

| Capability | Source status |
| --- | --- |
| Location display | GPS + reverse geocoding, lifecycle refresh and localized district/country label. |
| Prayer times | Home/prayer-times screen integration; calculated-time location limitation is noted above. |
| Current-prayer state | Home utilities/BLoC/widgets supply current/next progress UI. |
| Sunrise, sunset, Sehri, Iftar | Present in Home/prayer-time presentation widgets; values depend on timing response. |
| Calendars | Gregorian, Hijri (`hijri`) and Bangla date helpers/widgets. |
| Qiblah | `QiblahCompassScreen`, dependent on a supported calibrated device sensor. |

## Leaderboard, points and badges

The Leaderboard feature has a ranked list and user-detail screen and is
login-gated from the Home bottom navigation. Profile entities contain badges
and profile-completion data, while dashboard/backend flows provide
points/progress-related content.

The client integration is implemented, but scoring formulae, award rules and
live ranking integrity are backend concerns. Treat those as implemented flows
that still need server verification.

## Alarm and notification systems

### Alarms

The alarm package includes all-alarm, individual-alarm, bulk-setting and
ringing screens. Startup initializes `AlarmScheduler`, migrates/synchronizes
local alarms and handles cold-start notification actions. Infrastructure
includes `android_alarm_manager_plus`, timezone-aware scheduling,
`flutter_local_notifications`, Hive alarm/prayer-alarm storage and ringtone
repositories/caching.

### Notifications

Firebase is initialized before the app widget. Messaging services handle FCM
foreground/background messages, local notification presentation and token
registration/removal around authentication. Home has a notification badge and
`NotificationListScreen` loads application notifications.

`NotificationDetailScreen` explicitly has a TODO for its actual
content/layout. Routing exists, but notification detail presentation is
**not complete**.

Alarm delivery, exact-alarm policy, reboot recovery, action buttons and
lock-screen behavior must be validated on physical devices because they vary
by OS release and vendor restrictions.

## Authentication, profile and settings

| Flow | Current implementation |
| --- | --- |
| Email/password sign in | REST LoginBloc/use case; obtains available FCM token and persists the session. |
| Sign up and OTP/email verification | Dedicated registration and verification routes/BLoCs. |
| Forgot/reset password | Dedicated screens; Firebase service also supports reset email. |
| Google sign-in | Firebase/Google service exists. Sign-up's “Sign Up with Others” UI is explicitly disabled. |
| Guest access | Continues to Home with no stored token. |
| Session expiry | Refresh interceptor clears session and routes to sign-in. |

Profile supports remote/cached display, edit, image selection, password
change, deletion and logout. Settings include legal documents, language,
light/dark toggle, password change and deletion. Products, support and feedback
deliberately show coming-soon feedback. There is no separate selectable night
theme in the inspected preference state.

A family-members screen/service exists, but Profile comments out loading,
display and its link. It is not exposed by the active profile UI.

## Complete navigation structure

`AppRoutes.onGenerateRoute` is the named-route factory. It creates
feature-specific BLoCs where appropriate (for example Qur'an, Asmaul Husna
and notifications).

| Entry | Main path | Important nested destinations |
| --- | --- | --- |
| Splash | Splash → sign-in or Home | Startup/session decision. |
| Auth | Sign in/sign up | Verification, forgot/reset password. |
| Home | Home shell | Prayer times, compass, amal, alarms, Asmaul Husna, profile, notifications. |
| Qur'an | Intro once → Surah list | Reader, Para, tafsir, audio, bookmarks/history, playlists, plans, dashboard. |
| Hadith | Intro once → library | Collections, e-books/readers, categories, saved, plans, history, dashboard. |
| Quiz | Quiz shell | Questions/results/reviews, articles/tests, plans, dashboard. |
| Zikr | Intro/dashboard | Sets/counter/custom/plans/stats. |
| Dua | Intro/dashboard | Categories, reader and saved; Home entry is disabled. |
| Profile | Profile | Edit/settings/language/password/deletion; family UI disabled. |
| Notifications | List | Detail route exists; body unfinished. |

Guest browsing is supported. The code explicitly requires login for
Leaderboard, Hadith Planner/Dashboard and Quiz Planner/Dashboard. Other
server-backed routes may still require a valid session at the API level.

`RouteNames` has more constants than `AppRoutes` handles. A constant alone
is not documented as a reachable feature.

## Technical architecture

The larger features follow a pragmatic Clean Architecture layout:

```text
presentation/  screens, widgets, Bloc/Cubit, events, states
domain/        entities, repository contracts, use cases
data/          models, remote/local sources, repositories, services/stores
core/          networking, storage, localization, theme, routes, utilities
shared/        reusable state, Firebase services, global UI/services
```

Not every smaller feature uses every layer; some access a local service/store
directly. Major modules such as authentication, Hadith, Qur'an, Quiz and Home
use repository/use-case/BLoC separation.

## Project folder structure

```text
.
├── android/                         Android runner, permissions and services
├── ios/                             iOS runner, usage descriptions/background modes
├── assets/
│   ├── audio/ data/ database/ fonts/ hadith/ images/ language/
├── lib/
│   ├── core/                        auth, bloc, constants, errors, localization,
│   │                                network, services, storage, theme, utils, widgets
│   ├── features/                    19 application feature packages
│   ├── shared/                      shared BLoCs, Firebase services and widgets
│   ├── firebase_options.dart
│   └── main.dart                    bootstrap/composition root
├── test/
└── pubspec.yaml
```

## State management and data flow

The source contains **72 public BLoC/Cubit classes**. `flutter_bloc` is the
main reactive state mechanism; root providers include `LanguageBloc` and
`AppPreferencesBloc`.

```text
UI event → Bloc/Cubit → use case (where applicable) → repository
         → REST/Firebase/local store → state → BlocBuilder/BlocListener UI
```

For example, LoginBloc calls a login use case/repository/remote source;
Hadith's library, planner and dashboard BLoCs call repository/use-case flows.
The application also uses `ValueNotifier`-style shared globals for lightweight
profile/session state, so it is a hybrid state-management design rather than a
strict BLoC-only app.

## APIs, Firebase and local databases

### Networking and APIs

`DioClient` centralizes REST base URL configuration, headers, timeouts,
debug logging and auth refresh handling. Endpoint constants cover
accounts/profile, Home/amal, leaderboard, quiz/plans/articles, Hadith, Qur'an,
Asmaul Husna, alarms/ringtones and related resources.

Never copy API keys, authorization tokens, Firebase values or other
credentials into documentation or public issues. Confirm safe environment
configuration before production deployment.

### Firebase

- `firebase_core` initializes platform Firebase options.
- `firebase_auth` supports Firebase email/password and Google service paths.
- `firebase_messaging` handles FCM delivery and token state.
- Token registration is coordinated with the REST backend after authentication.

The app also uses REST session/auth code. Verify deployed-backend authorization
for Firebase/Google users; static source cannot prove that contract.

### Local persistence

| Store | Uses found |
| --- | --- |
| Hive / Hive Flutter | Auth/local state, alarms, prayer alarms, Asmaul Husna cache, zikr/custom-zikr/planner data. |
| SQLite (`sqflite`) | Offline Qur'an/local reading data and downloaded/local Hadith book/bookmark support. |
| SharedPreferences | Language/theme, intro flags and lightweight preferences/activity state. |
| File system/path provider | Downloaded audio and document/cache storage. |

## Offline and background functionality

Bundled Qur'an/Hadith resources, local Qur'an content, local bookmarks/history,
downloaded/local Hadith books, Hive zikr/alarm data, ringtone caching and
Surah audio support provide offline-oriented building blocks.

At startup the app registers background/foreground audio through
`audio_service`/`just_audio`, and restores/synchronizes alarms. Local
notification action or cold-start payload handling can open the ringing flow.

The presence of these components does not prove all offline/background cases:
test downloads, airplane mode, process death, reboot recovery and iOS
background limits on real devices.

## Localization and theme support

- English and Bangla text are provided through `AppText`, language resources,
  `LanguageBloc` and persisted preference.
- Forms use localized validators and failure messages.
- Location reverse geocoding requests English or Bangla native results based on
  current language.
- The root applies stored light/dark Material themes; no distinct night option
  was found.
- `flutter_screenutil` uses a 375×812 design baseline.

## Permissions and platform configuration

Android declares internet, wake lock, coarse/fine location, media-playback
foreground service, notifications, boot completed and alarm scheduling
capabilities. Its manifest also contains deliberate removal handling for
restricted exact-alarm/full-screen intent cases.

iOS declares when-in-use location and photo-library usage, and an audio
background mode. Actual FCM, notification, location, Google/Firebase and
background-audio behavior requires proper Xcode signing/capabilities.

Runtime testing is required for denial/deny-forever, disabled location,
notification/exact-alarm permissions, sensor calibration and app lifecycle
changes.

## App setup and build instructions

### Prerequisites

- Flutter/Dart compatible with `pubspec.yaml` (Dart `^3.12.0`).
- Android Studio/Xcode platform toolchains.
- Firebase configuration appropriate to the target build.
- A reachable backend compatible with the configured REST endpoints.

### Install and run

```bash
flutter pub get
flutter run
```

### Checks

```bash
flutter analyze
flutter test
```

### Build examples

```bash
flutter build apk
flutter build appbundle
flutter build ios
```

Before release, test real-device GPS, compass calibration, FCM, local
notifications, alarm actions, background audio and backend authentication.

## Feature implementation status

### Implemented client flows

Home/dashboard; Qur'an reader/audio/bookmark/history/plan/dashboard; Hadith
library/readers/saved/plans/history/dashboard; Quiz/learning/planner; Zikr and
amal; authentication/profile/settings; alarms and notification list all have
concrete screens, routes and/or state/data implementations.

### Partially implemented or intentionally disabled

| Area | Current state |
| --- | --- |
| Qur'an Learn tab | Opens `ComingSoonScreen`. |
| Qur'an page browsing | Explicitly described as coming soon. |
| Tajweed/download resource | Backend URL/versioning TODO. |
| Dua Home entry | Temporarily disabled; screens/routes remain. |
| Dua Planner | Tab is intentionally non-interactive; no planner screen. |
| Zikr stats tab | Screen/route remain but tab is hidden. |
| Profile family members | Loading/rendering/link are commented out. |
| Notification detail | Explicit TODO for actual detail layout/content. |
| Support/products/feedback | Settings show coming-soon feedback. |
| Social registration UI | Sign-up's Google/Facebook UI is disabled. |
| Some Hadith books | Unavailable catalog entries show coming soon. |

### Needs verification

| Area | Why static inspection is insufficient |
| --- | --- |
| Prayer-time calculations outside configured city | Service source uses fixed city/country despite dynamic label. |
| REST-backed data | Server availability, schema, auth and pagination are runtime concerns. |
| Firebase/Google/FCM | Provider setup, token registration and backend contract need live testing. |
| Alarms | OS policy, reboot and vendor battery management vary by device. |
| Audio/background | Platform audio session, downloads and lifecycle need device tests. |
| Compass/location | Hardware, calibration, permissions and native geocoding vary by region/device. |
| Offline operation | Verify in airplane mode and after restart/process death. |

## Known limitations and upcoming features

- Replace fixed-city prayer-time API inputs with coordinates.
- Complete Qur'an page-number browsing and the versioned Tajweed/download URL.
- Decide whether to expose the existing Dua flow from Home and build its
  planner.
- Restore/remove the hidden Zikr stats tab and disabled Profile family UI.
- Implement notification detail content and re-enable intended social sign-up
  UI if required.
- Validate unavailable Hadith content and all production backend, push,
  alarm, permission, audio and offline flows on Android and iOS.

## Documentation inventory

This README was produced by inspecting Dart source, routes/feature shells,
`pubspec.yaml`, assets, Android/iOS configuration, services, repositories and
storage code. The inventory found:

- **19 feature packages**;
- **101 public `Screen`/`Page` widget classes** under feature presentation
  screen directories;
- **72 public BLoC/Cubit classes**; and
- nested navigation systems for Home, Qur'an, Hadith, Quiz, Dua and Zikr.

These counts describe source structure, not a guarantee that every screen is
reachable or complete; the status sections above identify known exceptions.
