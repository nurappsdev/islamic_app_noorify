import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';

enum AmolDailyStatus { initial, loading, success, failure }

class AmolDailyState {
  const AmolDailyState._({required this.status, this.dashboard, this.failure});

  const AmolDailyState.initial() : this._(status: AmolDailyStatus.initial);

  const AmolDailyState.loading() : this._(status: AmolDailyStatus.loading);

  const AmolDailyState.success(AmolDailyDashboard dashboard)
    : this._(status: AmolDailyStatus.success, dashboard: dashboard);

  const AmolDailyState.failure(Failure failure)
    : this._(status: AmolDailyStatus.failure, failure: failure);

  final AmolDailyStatus status;
  final AmolDailyDashboard? dashboard;
  final Failure? failure;

  bool get isLoading => status == AmolDailyStatus.loading;
  bool get hasData => status == AmolDailyStatus.success && dashboard != null;
  String? get errorMessage => failure?.message;
}
