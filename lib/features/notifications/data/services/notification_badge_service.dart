import 'package:tuhfatul_muslim/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/repositories/notification_repository.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/usecases/get_notifications.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

/// Keeps [unreadNotificationCountNotifier] in sync with the server
/// (`GET /notifications`), the same way `ProfileService` keeps the cached
/// profile in sync. Used to show the Home AppBar bell's unread badge without
/// running the full notification list's `NotificationBloc`.
class NotificationBadgeService {
  NotificationBadgeService._();

  static final NotificationBadgeService instance =
      NotificationBadgeService._();

  final NotificationRepository _repository = NotificationRepositoryImpl(
    NotificationRemoteDataSourceImpl(),
  );
  late final GetNotifications _getNotifications = GetNotifications(
    _repository,
  );

  /// Fetches just enough to read the server's `unreadCount` and updates
  /// [unreadNotificationCountNotifier]. Failures (e.g. a guest with no
  /// session) are swallowed and leave the badge at its last known value.
  Future<void> refresh() async {
    final result = await _getNotifications(page: 1, limit: 1);
    result.fold((_) {}, (page) {
      unreadNotificationCountNotifier.value = page.unreadCount;
    });
  }

  /// Resets the badge (e.g. on sign-out).
  void reset() => unreadNotificationCountNotifier.value = 0;
}
