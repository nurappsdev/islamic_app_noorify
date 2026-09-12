import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/home/domain/entities/home_dashboard.dart';

enum HomeDashboardStatus { initial, loading, success, failure }

class HomeDashboardState {
  const HomeDashboardState._({
    required this.status,
    this.dashboard,
    this.failure,
  });

  const HomeDashboardState.initial()
    : this._(status: HomeDashboardStatus.initial);

  const HomeDashboardState.loading()
    : this._(status: HomeDashboardStatus.loading);

  const HomeDashboardState.success(HomeDashboard dashboard)
    : this._(status: HomeDashboardStatus.success, dashboard: dashboard);

  const HomeDashboardState.failure(Failure failure)
    : this._(status: HomeDashboardStatus.failure, failure: failure);

  final HomeDashboardStatus status;
  final HomeDashboard? dashboard;
  final Failure? failure;

  bool get isLoading => status == HomeDashboardStatus.loading;

  /// `true` once a real dashboard has been fetched, so widgets know to
  /// prefer it over their static placeholder content.
  bool get hasData =>
      status == HomeDashboardStatus.success && dashboard != null;

  String? get errorMessage => failure?.message;
}
