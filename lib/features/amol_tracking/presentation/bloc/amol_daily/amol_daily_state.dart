import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';

enum AmolDailyStatus { initial, loading, success, failure }

class AmolDailyState {
  const AmolDailyState._({
    required this.status,
    this.dashboard,
    this.failure,
    this.loggingItemKey,
    this.completionOverrides = const <String, bool>{},
  });

  const AmolDailyState.initial() : this._(status: AmolDailyStatus.initial);

  const AmolDailyState.loading({
    Map<String, bool> completionOverrides = const <String, bool>{},
  }) : this._(
         status: AmolDailyStatus.loading,
         completionOverrides: completionOverrides,
       );

  const AmolDailyState.success(
    AmolDailyDashboard dashboard, {
    Map<String, bool> completionOverrides = const <String, bool>{},
  }) : this._(
         status: AmolDailyStatus.success,
         dashboard: dashboard,
         completionOverrides: completionOverrides,
       );

  const AmolDailyState.failure(
    Failure failure, {
    Map<String, bool> completionOverrides = const <String, bool>{},
  }) : this._(
         status: AmolDailyStatus.failure,
         failure: failure,
         completionOverrides: completionOverrides,
       );

  final AmolDailyStatus status;
  final AmolDailyDashboard? dashboard;
  final Failure? failure;

  /// The `itemKey` currently being posted to `log-item`/`delete-item`, or
  /// `null` when nothing is in flight. Used to disable/spin just that one
  /// row.
  final String? loggingItemKey;

  /// `itemKey` -> the checked state the user last set locally this session.
  /// Once an item lands here it renders at that state regardless of what a
  /// later `GET` says `isCompleted` is, so a flaky/inconsistent backend read
  /// can't silently flip something the user just checked or unchecked.
  final Map<String, bool> completionOverrides;

  bool get isLoading => status == AmolDailyStatus.loading;
  bool get hasData => status == AmolDailyStatus.success && dashboard != null;
  String? get errorMessage => failure?.message;

  /// Whether [itemKey] should render checked, given the server's own
  /// [serverIsCompleted] and this session's [completionOverrides].
  bool isItemChecked(String itemKey, bool serverIsCompleted) =>
      completionOverrides[itemKey] ?? serverIsCompleted;

  AmolDailyState withLoggingItemKey(String? itemKey) => AmolDailyState._(
    status: status,
    dashboard: dashboard,
    failure: failure,
    loggingItemKey: itemKey,
    completionOverrides: completionOverrides,
  );

  /// Marks [itemKey] checked (or unchecked, when [checked] is `false`) in
  /// [completionOverrides] and, in the same update, records it as the
  /// in-flight `log-item`/`delete-item` request.
  AmolDailyState withOptimisticCompletion(String itemKey, bool checked) =>
      AmolDailyState._(
        status: status,
        dashboard: dashboard,
        failure: failure,
        loggingItemKey: itemKey,
        completionOverrides: {...completionOverrides, itemKey: checked},
      );
}
