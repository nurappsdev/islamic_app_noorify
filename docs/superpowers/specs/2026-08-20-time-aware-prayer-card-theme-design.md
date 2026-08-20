# Time-Aware Prayer Card Theme Design

## Goal

Change `PrayerTimeCard`'s background automatically according to the current time and the daily Fajr time for Mymensingh, Bangladesh.

## Theme schedule

The schedule uses local Bangladesh time and inclusive minute boundaries:

- From Fajr through 10:00 AM: `assets/images/theme1.png`
- From 10:01 AM through 4:00 PM: `assets/images/theme2.png`
- From 4:01 PM through 7:30 PM: `assets/images/theme3.png`
- From 7:31 PM until the next Fajr: `assets/images/theme4.png`

Seconds within a minute use that minute's theme. For example, 10:00:59 AM still uses theme 1 and 10:01:00 AM uses theme 2.

## Prayer-time source

Add a small service that calls AlAdhan's daily city endpoint over HTTPS:

`GET https://api.aladhan.com/v1/timingsByCity/{DD-MM-YYYY}?city=Mymensingh&country=Bangladesh&method=1&school=1`

- `method=1` selects University of Islamic Sciences, Karachi.
- `school=1` selects Hanafi Asr calculation.
- The service validates the HTTP status, AlAdhan response code, and `data.timings.Fajr` value.
- The parser accepts a leading `HH:mm` value even if the API appends a timezone suffix.

## Components

### Prayer time service

A focused service owns the HTTP request and converts the returned Fajr string into a local hour and minute. Networking and JSON parsing do not live in the widget.

### Theme resolver

A pure function receives the current local `DateTime` and today's Fajr hour/minute, then returns one of the four asset paths. Keeping this logic pure makes every minute boundary deterministic and testable.

### PrayerTimeCard state

`PrayerTimeCard` loads today's Fajr time when mounted. It displays immediately using a cached or fallback Fajr value rather than blocking the UI. After the request completes, it updates the theme if necessary.

The card schedules a timer for the next relevant boundary: Fajr, 10:01 AM, 4:01 PM, 7:31 PM, or midnight/day rollover. At day rollover it fetches the new day's Fajr time. The timer is cancelled when the widget is disposed.

## Cache and failure behavior

Persist the last successful Fajr value and its Gregorian date with `shared_preferences`. A cached value is used only for the same date. If the network fails and there is no same-day cache, use 5:00 AM as a display fallback.

API failure must not hide or replace the prayer card. The existing card remains visible with the best available theme. A later app/session load can retry the request.

## Data flow

1. The card reads the same-day cached Fajr value or the 5:00 AM fallback.
2. The pure resolver selects an initial background immediately.
3. The service requests today's AlAdhan timing for Mymensingh.
4. A valid response updates the cache, resolver input, and visible background.
5. The boundary timer updates the background without requiring navigation or an app restart.
6. Midnight triggers a fetch for the new date.

## Dependencies

Use the Dart `http` package for the HTTPS request and `shared_preferences` for the dated Fajr cache. Both dependencies remain behind the prayer-time service boundary.

## Testing

- Unit-test the resolver at Fajr, 10:00, 10:01, 4:00, 4:01, 7:30, and 7:31.
- Test the overnight interval before Fajr.
- Test successful AlAdhan parsing, malformed Fajr data, non-200 HTTP responses, and API error codes.
- Widget-test that `PrayerTimeCard` renders the asset returned for an injected clock and Fajr time.
- Run the complete Flutter test suite and static analysis.

## Scope

This change uses a fixed Mymensingh location. GPS permissions, location selection, full prayer-time display, and replacing the card's existing static prayer labels are outside this implementation.
