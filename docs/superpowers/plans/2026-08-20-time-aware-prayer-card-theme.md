# Time-Aware Prayer Card Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically select the prayer card background from four theme assets using Bangladesh local time and AlAdhan's daily Fajr time for Mymensingh.

**Architecture:** A pure schedule resolver owns all minute-boundary decisions. A focused AlAdhan service owns HTTP parsing and a dated `shared_preferences` cache, while `PrayerTimeCard` owns only loading state and a timer that re-evaluates the resolver at the next boundary.

**Tech Stack:** Flutter, Dart, `http`, `shared_preferences`, `flutter_test`, `http/testing`

**Spec:** `docs/superpowers/specs/2026-08-20-time-aware-prayer-card-theme-design.md`

## Global Constraints

- Location is fixed to Mymensingh, Bangladesh.
- AlAdhan calculation settings are University of Islamic Sciences, Karachi (`method=1`) and Hanafi (`school=1`).
- Theme boundaries are inclusive by minute: Fajr–10:00 theme 1, 10:01–16:00 theme 2, 16:01–19:30 theme 3, and 19:31–next Fajr theme 4.
- A same-date cache may replace the network result; stale dates must not be reused.
- The no-cache fallback Fajr time is 5:00 AM.
- The existing prayer card remains visible when network or response parsing fails.

---

### Task 1: Deterministic Prayer Theme Schedule

**Files:**
- Create: `lib/features/home/domain/prayer_theme_schedule.dart`
- Create: `test/prayer_theme_schedule_test.dart`

**Interfaces:**
- Produces: `PrayerClockTime({required int hour, required int minute})`
- Produces: `PrayerClockTime.totalMinutes`
- Produces: `prayerThemeAsset({required DateTime now, required PrayerClockTime fajr}) -> String`
- Produces: `nextPrayerThemeBoundary({required DateTime now, required PrayerClockTime fajr}) -> DateTime`

- [ ] **Step 1: Write failing boundary tests**

Create `test/prayer_theme_schedule_test.dart` with literal expectations for the requested minute boundaries:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

void main() {
  const fajr = PrayerClockTime(hour: 4, minute: 35);

  test('selects prayer card themes at every requested boundary', () {
    final cases = <(DateTime, String)>[
      (DateTime(2026, 8, 20, 4, 34), 'assets/images/theme4.png'),
      (DateTime(2026, 8, 20, 4, 35), 'assets/images/theme1.png'),
      (DateTime(2026, 8, 20, 10, 0, 59), 'assets/images/theme1.png'),
      (DateTime(2026, 8, 20, 10, 1), 'assets/images/theme2.png'),
      (DateTime(2026, 8, 20, 16, 0, 59), 'assets/images/theme2.png'),
      (DateTime(2026, 8, 20, 16, 1), 'assets/images/theme3.png'),
      (DateTime(2026, 8, 20, 19, 30, 59), 'assets/images/theme3.png'),
      (DateTime(2026, 8, 20, 19, 31), 'assets/images/theme4.png'),
    ];

    for (final (now, expected) in cases) {
      expect(prayerThemeAsset(now: now, fajr: fajr), expected);
    }
  });

  test('returns the next exact theme boundary', () {
    expect(
      nextPrayerThemeBoundary(
        now: DateTime(2026, 8, 20, 9, 45),
        fajr: fajr,
      ),
      DateTime(2026, 8, 20, 10, 1),
    );
    expect(
      nextPrayerThemeBoundary(
        now: DateTime(2026, 8, 20, 20),
        fajr: fajr,
      ),
      DateTime(2026, 8, 21),
    );
  });
}
```

- [ ] **Step 2: Run the schedule tests and verify RED**

Run: `flutter test test/prayer_theme_schedule_test.dart`

Expected: compilation fails because `prayer_theme_schedule.dart` and its public API do not exist.

- [ ] **Step 3: Implement the pure schedule**

Create `lib/features/home/domain/prayer_theme_schedule.dart`:

```dart
class PrayerClockTime {
  const PrayerClockTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;
}

String prayerThemeAsset({
  required DateTime now,
  required PrayerClockTime fajr,
}) {
  final minute = now.hour * 60 + now.minute;
  if (minute < fajr.totalMinutes) return 'assets/images/theme4.png';
  if (minute >= fajr.totalMinutes && minute <= 10 * 60) {
    return 'assets/images/theme1.png';
  }
  if (minute <= 16 * 60) return 'assets/images/theme2.png';
  if (minute <= 19 * 60 + 30) return 'assets/images/theme3.png';
  return 'assets/images/theme4.png';
}

DateTime nextPrayerThemeBoundary({
  required DateTime now,
  required PrayerClockTime fajr,
}) {
  final candidates = <DateTime>[
    DateTime(now.year, now.month, now.day, fajr.hour, fajr.minute),
    DateTime(now.year, now.month, now.day, 10, 1),
    DateTime(now.year, now.month, now.day, 16, 1),
    DateTime(now.year, now.month, now.day, 19, 31),
    DateTime(now.year, now.month, now.day + 1),
    DateTime(now.year, now.month, now.day + 1, fajr.hour, fajr.minute),
  ];
  return candidates.firstWhere((candidate) => candidate.isAfter(now));
}
```

- [ ] **Step 4: Run the schedule tests and verify GREEN**

Run: `flutter test test/prayer_theme_schedule_test.dart`

Expected: both tests pass with no render or analyzer warnings.

- [ ] **Step 5: Commit the schedule increment**

```bash
git add lib/features/home/domain/prayer_theme_schedule.dart test/prayer_theme_schedule_test.dart
git commit -m "feat: add prayer card theme schedule"
```

---

### Task 2: AlAdhan Fajr Service and Dated Cache

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/home/data/services/prayer_time_service.dart`
- Create: `test/prayer_time_service_test.dart`

**Interfaces:**
- Consumes: `PrayerClockTime` from Task 1
- Produces: abstract `PrayerTimeService.cachedFajr(DateTime date) -> PrayerClockTime?`
- Produces: abstract `PrayerTimeService.loadFajr(DateTime date) -> Future<PrayerClockTime>`
- Produces: `AladhanPrayerTimeService({required http.Client client, required SharedPreferences preferences})`
- Produces: `AladhanPrayerTimeService.create() -> Future<AladhanPrayerTimeService>`
- Produces: `bangladeshNow() -> DateTime`

- [ ] **Step 1: Add network and cache dependencies**

Add these dependency entries to `pubspec.yaml`:

```yaml
  http: ^1.6.0
  shared_preferences: ^2.5.5
```

Run: `flutter pub get`

Expected: dependency resolution succeeds and updates `pubspec.lock`.

- [ ] **Step 2: Write failing service tests**

Create `test/prayer_time_service_test.dart`. Use `MockClient` to return a real AlAdhan-shaped response and `SharedPreferences.setMockInitialValues({})` before each test:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('requests Karachi Hanafi timings and caches parsed Fajr', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'code': 200,
          'data': {
            'timings': {'Fajr': '04:23 (+06)'},
          },
        }),
        200,
      );
    });
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: client,
      preferences: preferences,
    );

    final fajr = await service.loadFajr(DateTime(2026, 8, 20));

    expect(fajr.hour, 4);
    expect(fajr.minute, 23);
    expect(requestedUri.queryParameters['city'], 'Mymensingh');
    expect(requestedUri.queryParameters['country'], 'Bangladesh');
    expect(requestedUri.queryParameters['method'], '1');
    expect(requestedUri.queryParameters['school'], '1');
  });

  test('returns same-day cache when the request fails', () async {
    SharedPreferences.setMockInitialValues({
      'fajr_date': '2026-08-20',
      'fajr_minutes': 263,
    });
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: MockClient((_) async => http.Response('unavailable', 503)),
      preferences: preferences,
    );

    final fajr = await service.loadFajr(DateTime(2026, 8, 20));

    expect((fajr.hour, fajr.minute), (4, 23));
  });

  test('returns 5 AM when response and dated cache are unavailable', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: MockClient((_) async => http.Response('{"code": 500}', 200)),
      preferences: preferences,
    );

    final fajr = await service.loadFajr(DateTime(2026, 8, 20));

    expect((fajr.hour, fajr.minute), (5, 0));
  });
}
```

- [ ] **Step 3: Run service tests and verify RED**

Run: `flutter test test/prayer_time_service_test.dart`

Expected: compilation fails because `PrayerTimeService` and `AladhanPrayerTimeService` do not exist.

- [ ] **Step 4: Implement request, parsing, cache, and fallback**

Create `lib/features/home/data/services/prayer_time_service.dart` with:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

abstract interface class PrayerTimeService {
  PrayerClockTime? cachedFajr(DateTime date);
  Future<PrayerClockTime> loadFajr(DateTime date);
}

class AladhanPrayerTimeService implements PrayerTimeService {
  AladhanPrayerTimeService({
    required http.Client client,
    required SharedPreferences preferences,
  }) : _client = client,
       _preferences = preferences;

  final http.Client _client;
  final SharedPreferences _preferences;

  static Future<AladhanPrayerTimeService> create() async {
    return AladhanPrayerTimeService(
      client: http.Client(),
      preferences: await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<PrayerClockTime> loadFajr(DateTime date) async {
    try {
      final uri = Uri.https(
        'api.aladhan.com',
        '/v1/timingsByCity/${_apiDate(date)}',
        const {
          'city': 'Mymensingh',
          'country': 'Bangladesh',
          'method': '1',
          'school': '1',
        },
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) throw const FormatException();
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] != 200) throw const FormatException();
      final data = body['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;
      final fajr = _parseFajr(timings['Fajr']);
      await _preferences.setString('fajr_date', _cacheDate(date));
      await _preferences.setInt('fajr_minutes', fajr.totalMinutes);
      return fajr;
    } catch (_) {
      return cachedFajr(date) ?? const PrayerClockTime(hour: 5, minute: 0);
    }
  }

  @override
  PrayerClockTime? cachedFajr(DateTime date) {
    if (_preferences.getString('fajr_date') != _cacheDate(date)) return null;
    final minutes = _preferences.getInt('fajr_minutes');
    if (minutes == null || minutes < 0 || minutes >= 24 * 60) return null;
    return PrayerClockTime(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static PrayerClockTime _parseFajr(Object? value) {
    final match = RegExp(r'^(\d{2}):(\d{2})').firstMatch(value?.toString() ?? '');
    if (match == null) throw const FormatException();
    return PrayerClockTime(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  static String _apiDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-${date.year}';

  static String _cacheDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime bangladeshNow() =>
    DateTime.now().toUtc().add(const Duration(hours: 6));
```

- [ ] **Step 5: Run service and schedule tests and verify GREEN**

Run: `flutter test test/prayer_time_service_test.dart test/prayer_theme_schedule_test.dart`

Expected: all service and schedule tests pass.

- [ ] **Step 6: Commit the service increment**

```bash
git add pubspec.yaml pubspec.lock lib/features/home/data/services/prayer_time_service.dart test/prayer_time_service_test.dart
git commit -m "feat: load and cache daily Fajr time"
```

---

### Task 3: Connect the Schedule to PrayerTimeCard

**Files:**
- Modify: `lib/features/home/presentation/widgets/prayer_time_card.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `PrayerTimeService.loadFajr(DateTime)` from Task 2
- Consumes: `prayerThemeAsset` and `nextPrayerThemeBoundary` from Task 1
- Extends: `PrayerTimeCard({PrayerTimeService? prayerTimeService, DateTime Function()? now})`

- [ ] **Step 1: Replace the fixed-asset widget assertion with injected-time cases**

In `test/widget_test.dart`, extract the existing PrayerTimeCard pump setup into a local helper that accepts a `PrayerTimeCard`, then add a fake service:

```dart
class _FakePrayerTimeService implements PrayerTimeService {
  _FakePrayerTimeService(this.fajr);
  final PrayerClockTime fajr;

  @override
  PrayerClockTime? cachedFajr(DateTime date) => fajr;

  @override
  Future<PrayerClockTime> loadFajr(DateTime date) async => fajr;
}
```

Add a widget test that pumps four cards with an injected clock and verifies the selected `AssetImage` after `pumpAndSettle()`:

```dart
final cases = <(DateTime, String)>[
  (DateTime(2026, 8, 20, 8), 'assets/images/theme1.png'),
  (DateTime(2026, 8, 20, 12), 'assets/images/theme2.png'),
  (DateTime(2026, 8, 20, 17), 'assets/images/theme3.png'),
  (DateTime(2026, 8, 20, 22), 'assets/images/theme4.png'),
];

for (final (now, asset) in cases) {
  await tester.pumpWidget(buildPrayerCard(
    PrayerTimeCard(
      prayerTimeService: _FakePrayerTimeService(
        const PrayerClockTime(hour: 4, minute: 30),
      ),
      now: () => now,
    ),
  ));
  await tester.pump();
  expect(find.byWidgetPredicate(
    (widget) => widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == asset,
  ), findsOneWidget);
}
```

Retain the existing assertions for visible card content, the painted arc, and the down-arrow.

- [ ] **Step 2: Run the widget test and verify RED**

Run: `flutter test test/widget_test.dart --plain-name 'prayer time card changes its background at scheduled times'`

Expected: compilation fails because `PrayerTimeCard` does not accept `prayerTimeService` or `now`.

- [ ] **Step 3: Convert PrayerTimeCard to stateful scheduling**

Change `PrayerTimeCard` to a `StatefulWidget` with optional injected dependencies:

```dart
class PrayerTimeCard extends StatefulWidget {
  const PrayerTimeCard({
    super.key,
    this.prayerTimeService,
    this.now,
  });

  final PrayerTimeService? prayerTimeService;
  final DateTime Function()? now;

  @override
  State<PrayerTimeCard> createState() => _PrayerTimeCardState();
}
```

In `_PrayerTimeCardState`, initialize Fajr to 5:00 AM, render immediately, then load and reschedule:

```dart
PrayerClockTime _fajr = const PrayerClockTime(hour: 5, minute: 0);
Timer? _boundaryTimer;

DateTime _now() => widget.now?.call() ?? bangladeshNow();

@override
void initState() {
  super.initState();
  _loadFajrAndSchedule();
}

Future<void> _loadFajrAndSchedule() async {
  final service = widget.prayerTimeService ??
      await AladhanPrayerTimeService.create();
  final date = _now();
  final cachedFajr = service.cachedFajr(date);
  if (mounted && cachedFajr != null) {
    setState(() => _fajr = cachedFajr);
  }
  final fajr = await service.loadFajr(date);
  if (!mounted) return;
  setState(() => _fajr = fajr);
  _scheduleNextBoundary();
}

void _scheduleNextBoundary() {
  _boundaryTimer?.cancel();
  final now = _now();
  final boundary = nextPrayerThemeBoundary(now: now, fajr: _fajr);
  _boundaryTimer = Timer(boundary.difference(now), () {
    if (!mounted) return;
    setState(() {});
    if (_now().day != now.day || _now().month != now.month ||
        _now().year != now.year) {
      _loadFajrAndSchedule();
    } else {
      _scheduleNextBoundary();
    }
  });
}

@override
void dispose() {
  _boundaryTimer?.cancel();
  super.dispose();
}
```

Replace the fixed background with:

```dart
Image.asset(
  prayerThemeAsset(now: _now(), fajr: _fajr),
  fit: BoxFit.cover,
)
```

Keep all other card layout and styling unchanged.

- [ ] **Step 4: Run the focused widget tests and verify GREEN**

Run: `flutter test test/widget_test.dart --plain-name 'prayer time card changes its background at scheduled times'`

Expected: all four injected-time cases pass without pending timers or render overflows.

- [ ] **Step 5: Run all feature tests**

Run: `flutter test test/prayer_theme_schedule_test.dart test/prayer_time_service_test.dart test/widget_test.dart`

Expected: all theme, service, and widget tests pass.

- [ ] **Step 6: Commit the widget integration**

```bash
git add lib/features/home/presentation/widgets/prayer_time_card.dart test/widget_test.dart
git commit -m "feat: change prayer card theme by daily time"
```

---

### Task 4: Final Quality Verification

**Files:**
- Verify: all files changed in Tasks 1–3

**Interfaces:**
- Consumes: the completed time-aware theme feature
- Produces: verified, formatted Flutter code with no analyzer findings

- [ ] **Step 1: Format all changed Dart files**

Run:

```bash
dart format \
  lib/features/home/domain/prayer_theme_schedule.dart \
  lib/features/home/data/services/prayer_time_service.dart \
  lib/features/home/presentation/widgets/prayer_time_card.dart \
  test/prayer_theme_schedule_test.dart \
  test/prayer_time_service_test.dart \
  test/widget_test.dart
```

Expected: formatter exits successfully.

- [ ] **Step 2: Run the complete test suite**

Run: `flutter test`

Expected: all tests pass with zero failures and no pending-timer or overflow exceptions.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 4: Check the final patch**

Run: `git diff --check && git status --short`

Expected: no whitespace errors; status lists only the intended feature files plus any pre-existing user changes.
