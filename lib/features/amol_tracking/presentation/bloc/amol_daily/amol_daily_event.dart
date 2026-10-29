import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';

abstract class AmolDailyEvent {
  const AmolDailyEvent();
}

/// Uses a fresh projected daily dashboard already held by the shared store.
/// No network request is made; this lets a feature such as Quran update the
/// Amol screen immediately when the user returns to it offline.
class UseAmolDailyDashboard extends AmolDailyEvent {
  const UseAmolDailyDashboard(this.dashboard);

  final AmolDailyDashboard dashboard;
}

/// Reapplies the Quran and dua reading held locally over the last server
/// checklist.
///
/// This contains no value because the reading progress stores are the one
/// durable source of the current cumulative offline duration.
class RefreshOfflineReadingProgress extends AmolDailyEvent {
  const RefreshOfflineReadingProgress();
}

/// Loads `GET /amol/tracker/daily?date=[date]` (`YYYY-MM-DD`, selected by the
/// frontend's location-aware Fajr-to-Fajr tracking cycle).
class LoadAmolDaily extends AmolDailyEvent {
  const LoadAmolDaily(this.date, {this.silent = false});

  final String date;

  /// A background refresh of a checklist that is already on screen: it does
  /// not switch the screen to its loading state (no flash of placeholders),
  /// and a failure leaves what is showing as it is.
  final bool silent;
}

/// Marks one checklist item done (`POST /amol/tracker/log-item`). The
/// screen only dispatches this after its own prayer-time gate passes.
class LogAmolDailyItem extends AmolDailyEvent {
  const LogAmolDailyItem({
    required this.logDate,
    required this.pillarKey,
    required this.itemKey,
  });

  final String logDate;
  final String pillarKey;
  final String itemKey;
}

/// Un-checks one checklist item (`DELETE /amol/tracker/delete-item`).
class UncheckAmolDailyItem extends AmolDailyEvent {
  const UncheckAmolDailyItem({
    required this.logDate,
    required this.pillarKey,
    required this.itemKey,
  });

  final String logDate;
  final String pillarKey;
  final String itemKey;
}
