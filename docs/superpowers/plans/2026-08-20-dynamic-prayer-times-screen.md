# Dynamic Prayer Times Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a routed Prayer Times screen matching `devImg/img_12.png` and populate it with the complete daily Karachi/Hanafi AlAdhan schedule.

**Architecture:** Expand the existing prayer service around a typed `DailyPrayerTimes` snapshot cached as dated JSON. Add pure current-prayer resolution, then build a deterministic, injectable screen that reuses the existing theme resolver and is opened from the home card arrow.

**Tech Stack:** Flutter, Dart, `http`, `shared_preferences`, `flutter_test`

**Spec:** `docs/superpowers/specs/2026-08-20-dynamic-prayer-times-screen-design.md`

## Global Constraints

- Use fixed Mymensingh, Bangladesh with AlAdhan `method=1` and `school=1`.
- Display Fajr, Sunrise, Dhuhr, Asr, Maghrib, Sunset, and Isha from one validated response.
- Alarm controls are visible and semantically disabled; notification scheduling is excluded.
- Same-day cached data renders immediately; stale cache is rejected.
- Missing data renders `--:--` and no active prayer instead of invented prayer values.
- Keep the existing four time-aware background rules unchanged.
- Merge into `ilmRepo` only after branch tests and analysis pass.

---

### Task 1: Full Daily Prayer Snapshot

**Files:**
- Create: `lib/features/home/domain/daily_prayer_times.dart`
- Modify: `lib/features/home/data/services/prayer_time_service.dart`
- Modify: `test/prayer_time_service_test.dart`

**Interfaces:**
- Produces: immutable `DailyPrayerTimes` with `dateKey`, `readableDate`, `hijriDate`, and seven `PrayerClockTime` values.
- Produces: `DailyPrayerTimes.toJson()` and `DailyPrayerTimes.fromJson(Map<String, dynamic>)`.
- Replaces service API with `cachedPrayerTimes(DateTime)` and `loadPrayerTimes(DateTime)`.
- Retains convenience Fajr fallback in the card when no snapshot exists.

- [ ] **Step 1: Write failing full-response and cache tests**

Update the successful service fixture to include:

```dart
'timings': {
  'Fajr': '04:23 (+06)',
  'Sunrise': '05:40 (+06)',
  'Dhuhr': '12:08 (+06)',
  'Asr': '16:32 (+06)',
  'Maghrib': '18:35 (+06)',
  'Sunset': '18:35 (+06)',
  'Isha': '19:55 (+06)',
},
'date': {
  'readable': '20 Aug 2026',
  'gregorian': {'date': '20-08-2026'},
  'hijri': {
    'day': '07',
    'year': '1448',
    'month': {'en': 'Safar'},
  },
},
```

Assert `loadPrayerTimes` returns every literal time, `readableDate == '20 Aug 2026'`, `hijriDate == '7 Safar 1448 Hijri'`, and writes a JSON cache. Recreate the service with a failing client and assert `cachedPrayerTimes` round-trips the same snapshot. Add a malformed test with a missing `Isha` field and expect `loadPrayerTimes` to return null when no cache exists.

- [ ] **Step 2: Run service tests to verify RED**

Run: `flutter test test/prayer_time_service_test.dart`

Expected: compilation fails because `DailyPrayerTimes`, `loadPrayerTimes`, and `cachedPrayerTimes` do not exist.

- [ ] **Step 3: Implement the model and service migration**

Create `DailyPrayerTimes` with value fields, JSON conversion, and:

```dart
String formatPrayerTime(PrayerClockTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
```

Change `PrayerTimeService` to:

```dart
abstract interface class PrayerTimeService {
  DailyPrayerTimes? cachedPrayerTimes(DateTime date);
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date);
}
```

Parse all required fields before caching. Store the snapshot with keys `prayer_times_date` and `prayer_times_json`. On HTTP, API-code, JSON, or validation failure, return the same-day cache or null.

- [ ] **Step 4: Run service tests to verify GREEN**

Run: `flutter test test/prayer_time_service_test.dart`

Expected: full parsing, cache round-trip, stale cache, and malformed-response tests pass.

- [ ] **Step 5: Commit Task 1**

```bash
git add lib/features/home/domain/daily_prayer_times.dart lib/features/home/data/services/prayer_time_service.dart test/prayer_time_service_test.dart
git commit -m "feat: load complete daily prayer schedule"
```

---

### Task 2: Current Prayer Resolution

**Files:**
- Create: `lib/features/home/domain/current_prayer.dart`
- Create: `test/current_prayer_test.dart`

**Interfaces:**
- Produces: enum `PrayerPeriod { fajr, dhuhr, asr, maghrib, isha }`.
- Produces: `PrayerPeriod? currentPrayerPeriod(DateTime now, DailyPrayerTimes times)`.
- Produces: `PrayerClockTime prayerStart(PrayerPeriod, DailyPrayerTimes)` and nullable `prayerEnd`.

- [ ] **Step 1: Write failing interval tests**

Create a literal `DailyPrayerTimes` fixture and assert:

```dart
expect(currentPrayerPeriod(DateTime(2026, 8, 20, 4, 23), times), PrayerPeriod.fajr);
expect(currentPrayerPeriod(DateTime(2026, 8, 20, 6), times), isNull);
expect(currentPrayerPeriod(DateTime(2026, 8, 20, 12, 8), times), PrayerPeriod.dhuhr);
expect(currentPrayerPeriod(DateTime(2026, 8, 20, 16, 32), times), PrayerPeriod.asr);
expect(currentPrayerPeriod(DateTime(2026, 8, 20, 18, 35), times), PrayerPeriod.maghrib);
expect(currentPrayerPeriod(DateTime(2026, 8, 20, 19, 55), times), PrayerPeriod.isha);
expect(currentPrayerPeriod(DateTime(2026, 8, 20, 2), times), PrayerPeriod.isha);
```

- [ ] **Step 2: Run domain tests to verify RED**

Run: `flutter test test/current_prayer_test.dart`

Expected: compilation fails because the current-prayer API does not exist.

- [ ] **Step 3: Implement ordered minute comparisons**

Use `now.hour * 60 + now.minute` and these intervals: Fajr–Sunrise, Dhuhr–Asr, Asr–Maghrib, Maghrib–Isha, and Isha–midnight plus midnight–Fajr. Return null for Sunrise–Dhuhr.

- [ ] **Step 4: Run domain tests to verify GREEN**

Run: `flutter test test/current_prayer_test.dart`

Expected: all seven interval cases pass.

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/features/home/domain/current_prayer.dart test/current_prayer_test.dart
git commit -m "feat: resolve current daily prayer"
```

---

### Task 3: Migrate PrayerTimeCard and Add Navigation

**Files:**
- Modify: `lib/features/home/presentation/widgets/prayer_time_card.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: full `PrayerTimeService` snapshot API.
- Produces: tappable yellow arrow that pushes `RouteNames.prayerTimes`.

- [ ] **Step 1: Write failing card migration and navigation tests**

Change `_FakePrayerTimeService` to return a `DailyPrayerTimes` fixture. Add a `MaterialApp` route spy for `RouteNames.prayerTimes`, tap `Icons.keyboard_arrow_down`, and assert the destination marker appears.

- [ ] **Step 2: Run focused widget tests to verify RED**

Run: `flutter test test/widget_test.dart --plain-name 'prayer card arrow opens prayer times route'`

Expected: test fails because the arrow has no tap callback and the fake uses the new service API.

- [ ] **Step 3: Migrate card state and arrow behavior**

Store `DailyPrayerTimes? _times`; derive Fajr as `_times?.fajr ?? const PrayerClockTime(hour: 5, minute: 0)`. Load cache then remote snapshot. Replace the arrow container with an `IconButton` whose tooltip is `View prayer times` and callback is:

```dart
Navigator.of(context).pushNamed(RouteNames.prayerTimes);
```

- [ ] **Step 4: Run existing and navigation widget tests to verify GREEN**

Run: `flutter test test/widget_test.dart`

Expected: existing card layout/theme tests and arrow navigation test pass.

- [ ] **Step 5: Commit Task 3**

```bash
git add lib/features/home/presentation/widgets/prayer_time_card.dart test/widget_test.dart
git commit -m "feat: open prayer times from home card"
```

---

### Task 4: Dynamic Prayer Times Screen

**Files:**
- Create: `lib/features/home/presentation/screens/prayer_times_screen.dart`
- Modify: `lib/core/constants/app_routes.dart`
- Create: `test/prayer_times_screen_test.dart`

**Interfaces:**
- Produces: `PrayerTimesScreen({PrayerTimeService? prayerTimeService, DateTime Function()? now})`.
- Consumes: `DailyPrayerTimes`, current-prayer resolver, and theme resolver.
- Registers: `RouteNames.prayerTimes` in `AppRoutes`.

- [ ] **Step 1: Write failing screen tests**

Pump the screen with a fake service and fixed 4:40 PM clock. Assert:

- `Prayer times`, `Mymensingh, Bangladesh`, and all five prayer names render.
- Literal API values `4:23 AM`, `12:08 PM`, `4:32 PM`, `6:35 PM`, and `7:55 PM` render.
- `assets/images/theme3.png` is the summary background.
- The Asr row is the only row with key `active-prayer-row`.
- Five alarm icons render with the semantic hint `Alarm scheduling coming later`.
- Tapping the back button pops the route.

- [ ] **Step 2: Run screen tests to verify RED**

Run: `flutter test test/prayer_times_screen_test.dart`

Expected: compilation fails because `PrayerTimesScreen` does not exist.

- [ ] **Step 3: Build the reference-aligned screen**

Implement a `StatefulWidget` with cached-first refresh. Build:

- Olive `Scaffold` and safe header row.
- 290.h summary stack using the active theme image, olive overlay, arc painter, dates, live time/location, current-prayer badge, sunrise, and sunset.
- `Expanded` white rounded-top sheet with five `_PrayerRow` widgets in a vertical timeline.
- Active row key and thicker olive border.
- Disabled alarm `IconButton` widgets wrapped in `Semantics(hint: 'Alarm scheduling coming later')`.
- `--:--` values and no active key when `_times == null`.

Register the route:

```dart
case RouteNames.prayerTimes:
  return _page(const PrayerTimesScreen(), settings);
```

- [ ] **Step 4: Run screen and routing tests to verify GREEN**

Run: `flutter test test/prayer_times_screen_test.dart test/widget_test.dart`

Expected: dynamic rows, active styling, header theme, back behavior, and arrow route pass without overflows.

- [ ] **Step 5: Commit Task 4**

```bash
git add lib/features/home/presentation/screens/prayer_times_screen.dart lib/core/constants/app_routes.dart test/prayer_times_screen_test.dart
git commit -m "feat: add dynamic prayer times screen"
```

---

### Task 5: Verification and Local Merge

**Files:**
- Verify all feature files and commits.
- Merge `feature/time-aware-prayer-themes` into `ilmRepo`.

- [ ] **Step 1: Format changed Dart files**

Run: `dart format lib/features/home test`

Expected: formatter exits successfully.

- [ ] **Step 2: Verify feature branch**

Run: `flutter test`

Expected: zero failures, pending timers, or overflow exceptions.

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 3: Inspect the patch**

Run: `git diff --check ilmRepo...HEAD` and `git status --short`.

Expected: no whitespace errors and a clean feature worktree.

- [ ] **Step 4: Merge locally and reverify**

From the main checkout, merge `feature/time-aware-prayer-themes` into `ilmRepo` without pulling remote changes. Run `flutter test` and `flutter analyze` on the merged checkout.

Expected: all tests pass and analysis reports no issues.

- [ ] **Step 5: Clean up only after merged verification**

Remove `/private/tmp/islami_app_noorify-time-aware-prayer-themes`, prune worktrees, and delete the merged feature branch with `git branch -d feature/time-aware-prayer-themes`.
