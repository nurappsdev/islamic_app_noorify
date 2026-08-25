# Dynamic Prayer Times Screen Design

## Goal

Open a full-screen Prayer Times page from the yellow arrow on `PrayerTimeCard`. Match the structure and visual hierarchy of `devImg/img_12.png` while displaying live daily prayer times from AlAdhan for Mymensingh, Bangladesh.

## Scope

This increment includes:

- A routed Prayer Times screen.
- Dynamic Fajr, Sunrise, Dhuhr, Asr, Maghrib, Sunset, and Isha values.
- Dynamic Gregorian and Hijri date values returned by AlAdhan.
- Current-prayer detection and row highlighting.
- The existing time-aware theme selection in the summary header.
- Visible alarm controls matching the reference design.

Scheduling alarms, notifications, permission prompts, and persistence of alarm selections are explicitly deferred.

## Prayer-time data model

Replace the Fajr-only service result with a typed `DailyPrayerTimes` snapshot containing:

- Gregorian date key and readable date.
- Hijri day, month, and year text.
- Fajr, Sunrise, Dhuhr, Asr, Maghrib, Sunset, and Isha as validated hour/minute values.

The model exposes formatted 12-hour display values and ordered prayer intervals. The home card reads Fajr from the same snapshot, ensuring its theme boundary matches the Prayer Times screen.

## API and calculation settings

Continue using:

`GET https://api.aladhan.com/v1/timingsByCity/{DD-MM-YYYY}?city=Mymensingh&country=Bangladesh&method=1&school=1`

- `method=1`: University of Islamic Sciences, Karachi.
- `school=1`: Hanafi Asr.
- The parser accepts a leading `HH:mm` when AlAdhan adds a timezone suffix.
- A response is valid only when the HTTP status, AlAdhan response code, required timing fields, and date fields are valid.

## Cache and failure behavior

Persist the complete validated snapshot as JSON in `shared_preferences`, keyed by its Gregorian date. A same-day cached snapshot is displayed immediately and refreshed from the API.

If refresh fails, keep the same-day cached snapshot. If neither API nor same-day cache is available:

- Keep the screen layout visible.
- Show `--:--` for unavailable times.
- Show the device-derived Gregorian date and a neutral Hijri placeholder.
- Do not invent prayer times or identify a current prayer.

The home card retains its 5:00 AM theme fallback when no valid snapshot exists so its background remains usable offline.

## Navigation

Add `PrayerTimesScreen` to `AppRoutes` for `RouteNames.prayerTimes`.

The yellow circular arrow in `PrayerTimeCard` becomes a semantic button. Tapping it calls `Navigator.of(context).pushNamed(RouteNames.prayerTimes)`. The back button on the new screen calls `Navigator.of(context).pop()`.

## Screen layout

### Summary header

The upper section follows `img_12.png`:

- Olive page background.
- Safe-area back button and centered “Prayer times” title.
- API-derived Hijri date on the left and API-derived readable Gregorian date on the right. Bengali calendar conversion is outside this increment.
- Semicircular progress arc with a sun marker.
- Centered readable date, current clock, and “Mymensingh, Bangladesh”.
- Current-prayer badge showing the prayer name and its start/end interval.
- Sunrise and sunset labels at the bottom.

The header selects `theme1.png` through `theme4.png` using the existing resolver and the snapshot's Fajr time. A translucent olive treatment keeps the reference palette and text contrast consistent across all four images.

### Prayer list sheet

A white rounded-top sheet fills the lower screen and contains five rows:

1. Fajr
2. Dhuhr
3. Asr
4. Maghrib & Iftar
5. Isha

Each row contains:

- A left timeline dot.
- A pale icon tile with a prayer-appropriate icon.
- Prayer name and API-derived time or interval.
- A trailing alarm icon.

The active prayer row uses a thicker olive outline. Alarm controls are rendered for visual fidelity but have no callback in this increment. A small “Coming later” tooltip or semantic hint communicates the deferred behavior without altering the reference layout.

## Current-prayer calculation

Determine the active interval from ordered daily times:

- Fajr: Fajr to Sunrise.
- Dhuhr: Dhuhr to Asr.
- Asr: Asr to Maghrib.
- Maghrib & Iftar: Maghrib to Isha.
- Isha: Isha through midnight and before the next Fajr.

The post-Sunrise, pre-Dhuhr interval has no active prayer row. The summary badge may show “Next: Dhuhr” in this interval. Missing snapshot data produces no active interval.

## State and refresh

The screen is stateful and uses the same service boundary as the home card:

1. Create or inject a prayer-time service.
2. Read the same-day cache and render it immediately.
3. Refresh from AlAdhan.
4. Update the UI with the validated snapshot.
5. Schedule a timer for the next prayer or theme boundary so the highlighted row, clock, summary, and background remain current while the screen stays open.
6. Refresh the daily snapshot after midnight.

Injected service and clock dependencies keep widget tests deterministic.

## Testing

- Service tests cover full snapshot parsing, complete cache round-trip, stale cache rejection, malformed required fields, non-200 responses, and API error codes.
- Domain tests cover each current-prayer interval and the Sunrise-to-Dhuhr gap.
- Widget tests verify all five API-derived prayer rows, active-row styling, theme-aware header asset, placeholder state, back navigation, and yellow-arrow navigation.
- Existing time-aware card tests remain green.
- Final verification runs `dart format`, `flutter test`, `flutter analyze`, and `git diff --check`.

## Merge sequence

After the feature branch is fully verified:

1. Merge `feature/time-aware-prayer-themes` into `ilmRepo` locally.
2. Run the complete test suite and analyzer on the merged `ilmRepo` checkout.
3. Remove the isolated worktree and delete the feature branch only after merged verification passes.
