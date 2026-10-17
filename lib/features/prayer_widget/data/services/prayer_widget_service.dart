import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_location_service.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/calendar/date_labels.dart';
import 'package:tuhfatul_muslim/features/home/domain/current_prayer.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_location.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Mirrors `PrayerLocationText._label` exactly, so the widget's centre-block
/// location line shows the same "finding your location…"/"permission
/// denied"/etc. placeholder the home card shows while [PrayerLocationService]
/// hasn't resolved a location yet, instead of going blank.
String _locationLabel(AppText appText) {
  final state = PrayerLocationService.instance.state;
  final location = state.location?.districtCountryDisplayName ?? '';
  if (location.isNotEmpty) return location;
  return switch (state.status) {
    PrayerLocationStatus.idle ||
    PrayerLocationStatus.locating => appText.locationFinding,
    PrayerLocationStatus.serviceDisabled => appText.locationServiceDisabled,
    PrayerLocationStatus.permissionDenied ||
    PrayerLocationStatus.permissionDeniedForever =>
      appText.locationPermissionDenied,
    PrayerLocationStatus.unavailable => appText.locationUnavailable,
    PrayerLocationStatus.ready => appText.locationUnavailable,
  };
}

/// Keeps the native Home Screen prayer widget (Android `AppWidgetProvider`
/// + iOS WidgetKit extension) filled with the same prayer schedule the
/// in-app [PrayerTimeCard] shows — reusing [AladhanPrayerTimeService] for the
/// data and [PrayerLocationService] for the display-only location label, the
/// same split the card itself uses.
///
/// The widget reads everything through `home_widget`'s shared storage
/// (`SharedPreferences` on Android, an App Group `UserDefaults` on iOS) as
/// plain strings, since the native widget code has no access to the Dart
/// localization/theme system. Each of the five daily prayers is written as a
/// `<period>_label` (already localized through [AppText]), `<period>_time`
/// (a bare localized clock, e.g. "৪:৪১") and `<period>_minutes` (minutes
/// since midnight) triple; the native side works out which one is current
/// itself at render time (mirroring `currentPrayerPeriod`) and highlights
/// that cell, so a stale sync never shows a prayer that has already passed
/// as the active one.
class PrayerWidgetService {
  PrayerWidgetService._();

  static const appGroupId = 'group.com.tuhfatulmuslim.app.widget';

  // `home_widget` resolves `androidName` against the app's own package
  // itself (`<applicationId>.<androidName>`), so this must be the bare
  // class name, not pre-qualified — passing the qualified name here doubles
  // the package prefix and the provider fails to resolve at runtime.
  static const _androidProviderName = 'PrayerTimesWidgetProvider';
  static const _iosWidgetName = 'PrayerTimesWidget';

  /// The URI the widget's manual refresh button broadcasts - matched by
  /// [refreshPrayerWidgetCallback] and built into the native refresh icon's
  /// `HomeWidgetBackgroundIntent` (Android) / `AppIntent` (iOS).
  static const refreshUriHost = 'refresh-widget';

  static const _periods = [
    PrayerPeriod.fajr,
    PrayerPeriod.dhuhr,
    PrayerPeriod.asr,
    PrayerPeriod.maghrib,
    PrayerPeriod.isha,
  ];

  static bool _initialized = false;
  static Future<void>? _inFlightSync;

  /// Sets the iOS App Group once for the process. Safe to call repeatedly;
  /// a no-op (and harmless) on Android.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('[PrayerWidget] setAppGroupId failed: $e');
    }
  }

  /// Best-effort refresh of the widget's data, reusing whatever prayer
  /// schedule is already cached for [now] and only reaching the network
  /// when nothing is cached yet for that date — the same cache
  /// [AladhanPrayerTimeService] and the home card already share, so this
  /// never triggers a second API call for a date the app already fetched.
  ///
  /// Concurrent calls collapse into the one already running, so firing this
  /// from app start, a location update and the "Add Widget" screen at once
  /// still only does the work once.
  static Future<void> syncPrayerWidget({
    PrayerTimeService? prayerTimeService,
    DateTime Function()? now,
    AppLanguage? language,
  }) {
    final existing = _inFlightSync;
    if (existing != null) return existing;
    final future = _sync(prayerTimeService, now, language);
    _inFlightSync = future;
    return future.whenComplete(() => _inFlightSync = null);
  }

  static Future<void> _sync(
    PrayerTimeService? prayerTimeService,
    DateTime Function()? nowFn,
    AppLanguage? language,
  ) async {
    try {
      await init();
      final current = (nowFn ?? bangladeshNow)();
      final service =
          prayerTimeService ?? await AladhanPrayerTimeService.create();
      var times = service.cachedPrayerTimes(current);
      times ??= await service.loadPrayerTimes(current);
      if (times == null) return;

      final resolvedLanguage = language ?? LanguagePreference.current;
      final appText = AppText.forLanguage(resolvedLanguage);
      final bangla = resolvedLanguage == AppLanguage.bangla;
      final location = PrayerLocationService.instance.state.location;
      final area = location?.shortDisplayName ?? '';
      String edgeLabel(String label) => area.isEmpty ? label : '$label, $area';
      String clock(PrayerClockTime t) =>
          localizedPeriodClock(t, times: times, appText: appText, bangla: bangla);
      // A bare "৪:৪১"-style clock (no period-name prefix) for the five-prayer
      // row, where each cell already carries its own prayer name - repeating
      // it in the time too would just make the cell too wide for its space.
      String shortClock(PrayerClockTime t) {
        final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
        final minute = t.minute.toString().padLeft(2, '0');
        return localizeDigits('$hour:$minute', bangla: bangla);
      }

      // Same background art PrayerTimeCard shows for this time of day
      // (`prayerThemeAsset`), reduced to the "1".."4" suffix the native
      // bundled images are named with (`prayer_theme_<n>`).
      final themeAsset = prayerThemeAsset(now: current, fajr: times.fajr);
      final themeKey =
          RegExp(r'theme(\d)\.png$').firstMatch(themeAsset)?.group(1) ?? '4';

      final data = <String, String>{
        'widget_theme': themeKey,
        // Top date row, as on the card: Hijri at the start, Bengali calendar
        // at the end.
        'widget_hijri_date': hijriDateLabel(
          current,
          bangla: bangla,
          maghrib: times.maghrib,
        ),
        'widget_calendar_date': banglaDateLabel(current, english: !bangla),
        // Centre block: Gregorian date, the day-period-labelled clock (e.g.
        // "সুবহে সাদিক ৫:৪৪", accurate as of this sync - periodic like the
        // rest of the widget, not a live tick), and the verified
        // district/country.
        'widget_greg_date': localizeDigits(
          '${current.day} ${appText.monthNames[current.month - 1]} ${current.year}',
          bangla: bangla,
        ),
        'widget_period_time': clock(
          PrayerClockTime(hour: current.hour, minute: current.minute),
        ),
        'widget_location': _locationLabel(appText),
        // Short, friendly call-to-action under the clock - native highlights
        // whichever of the five cells below is current, so this just invites
        // tapping through to the app rather than restating it.
        'widget_amol_tagline': appText.widgetAmolTagline,
        // The current-prayer cell still needs these to build its own label -
        // native recomputes *which* of the five below is current from their
        // minutes, then assembles "<name> <namazWord>" itself, exactly as
        // the card does, so a widget that hasn't synced in a while never
        // shows a period that has already passed.
        'widget_namaz_word': appText.namazWord,
        'widget_ishraq_label': appText.naflIshraq,
        // Sunrise/sunset edge row, each with its own local area. Sunrise's
        // minutes are also the start of the Ishraq gap `currentPrayerPeriod`
        // leaves between Fajr and Dhuhr.
        'widget_sunrise_label': edgeLabel(appText.sunrise),
        'widget_sunrise_time': clock(times.sunrise),
        'widget_sunrise_minutes': times.sunrise.totalMinutes.toString(),
        'widget_sunset_label': edgeLabel(appText.sunset),
        'widget_sunset_time': clock(times.sunset),
      };
      for (final period in _periods) {
        final key = period.name;
        final time = prayerStart(period, times);
        data['${key}_label'] = period.displayName(appText);
        // The five-prayer row shows a bare clock per cell - `shortClock()`,
        // not the period-prefixed `clock()` the old single badge used, which
        // would overflow a narrow cell.
        data['${key}_time'] = shortClock(time);
        data['${key}_minutes'] = time.totalMinutes.toString();
      }

      for (final entry in data.entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
      }

      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iosWidgetName,
      );
      await _scheduleBoundaryUpdates(current, times);
    } catch (e) {
      // Best-effort: the widget keeps showing its last good data, and the
      // next sync (app start, location change, boundary alarm) tries again.
      debugPrint('[PrayerWidget] sync failed: $e');
    }
  }

  /// Arms native updates (Android `AlarmManager`, via `home_widget`) for
  /// every remaining prayer boundary today, plus tomorrow's Fajr — the
  /// moments the "next prayer" actually changes — instead of polling on an
  /// unrestricted timer. A no-op on iOS, where the WidgetKit
  /// `TimelineProvider` schedules its own entries for the same boundaries.
  ///
  /// Also includes the background-art boundaries `prayerThemeAsset` switches
  /// on (10:00, 16:00, 19:30), so the widget's picture keeps following the
  /// time of day the way the home card's does, not just the prayer times.
  static Future<void> _scheduleBoundaryUpdates(
    DateTime now,
    DailyPrayerTimes times,
  ) async {
    DateTime atMinutes(DateTime day, int minutes) => DateTime(
      day.year,
      day.month,
      day.day,
    ).add(Duration(minutes: minutes));

    final prayerBoundaries = _periods.map(
      (p) => atMinutes(now, prayerStart(p, times).totalMinutes),
    );
    const themeBoundaryMinutes = [10 * 60 + 1, 16 * 60 + 1, 19 * 60 + 31];
    final themeBoundaries = themeBoundaryMinutes.map(
      (minutes) => atMinutes(now, minutes),
    );
    final tomorrowFajr = atMinutes(
      now.add(const Duration(days: 1)),
      times.fajr.totalMinutes,
    );

    final upcoming = [...prayerBoundaries, ...themeBoundaries, tomorrowFajr]
        .where((time) => time.isAfter(now))
        .toList()
      ..sort();

    try {
      await HomeWidget.scheduleWidgetUpdates(
        upcoming,
        androidName: _androidProviderName,
      );
    } catch (e) {
      debugPrint('[PrayerWidget] scheduleWidgetUpdates failed: $e');
    }
  }

  /// Whether the device supports pinning the Android widget directly from
  /// the app (API 26+ with a launcher that implements it). Always `false`
  /// on iOS, which has no such API.
  static Future<bool> isPinSupported() async {
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Asks the launcher to add the widget to the Home Screen (Android only).
  static Future<void> requestPin() async {
    try {
      await HomeWidget.requestPinWidget(androidName: _androidProviderName);
    } catch (e) {
      debugPrint('[PrayerWidget] requestPinWidget failed: $e');
    }
  }
}

/// Entry point for the widget's manual refresh button
/// (`HomeWidget.registerInteractivityCallback`, registered once in `main()`).
///
/// Runs in a fresh background isolate with none of `main()`'s startup state
/// (no Hive, no [LanguagePreference.current] already set from the saved
/// preference), so it reads the saved language itself rather than trusting
/// that default, and otherwise reuses the exact same [PrayerWidgetService]
/// sync path app-launch and boundary-alarm updates already go through.
///
/// Must stay a plain top-level function (not a class member) - the
/// `home_widget` plugin looks it up by callback handle via
/// `PluginUtilities.getCallbackHandle`, which only resolves top-level and
/// static functions.
@pragma('vm:entry-point')
Future<void> refreshPrayerWidgetCallback(Uri? uri) async {
  if (uri?.host != PrayerWidgetService.refreshUriHost) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await PrayerWidgetService.syncPrayerWidget(
      language: LanguagePreference.read(prefs),
    );
  } catch (e) {
    debugPrint('[PrayerWidget] manual refresh failed: $e');
  }
}
