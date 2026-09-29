import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/entities/notification_entity.dart';

/// initial/loading/success/failure, mirroring every other list bloc in the
/// app (e.g. `QuizStatus`). Loading the next page doesn't change [status] —
/// it's tracked separately by [NotificationState.isLoadingMore], the same
/// way `QuizState.isLoadingMore` overlays `QuizStatus.success`.
enum NotificationStatus { initial, loading, success, failure }

class NotificationState {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.page = 0,
    this.totalPage = 0,
    this.unreadCount = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.refreshTick = 0,
    this.markingReadId,
    this.markReadFailure,
    this.markReadFailureTick = 0,
  });

  final NotificationStatus status;

  /// Every notification loaded so far, across all pages, most recent first.
  final List<NotificationEntity> notifications;
  final int page;
  final int totalPage;
  final int unreadCount;
  final bool hasMore;
  final bool isLoadingMore;
  final Failure? failure;

  /// Bumped every time a [RefreshNotifications] finishes, success or failure,
  /// so pull-to-refresh can detect completion even on a failure (which
  /// otherwise leaves every other field unchanged).
  final int refreshTick;

  /// The id of the notification currently being marked read, or `null` when
  /// none is in flight. Lets the card show a small inline spinner instead of
  /// its unread dot while the request is out.
  final String? markingReadId;

  /// The most recent `MarkNotificationAsRead` failure, if any - a transient
  /// signal for a listener (e.g. a SnackBar), paired with
  /// [markReadFailureTick] so the same kind of failure twice in a row still
  /// triggers it a second time.
  final Failure? markReadFailure;
  final int markReadFailureTick;

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationEntity>? notifications,
    int? page,
    int? totalPage,
    int? unreadCount,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
    int? refreshTick,
    String? markingReadId,
    bool clearMarkingReadId = false,
    Failure? markReadFailure,
    int? markReadFailureTick,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      totalPage: totalPage ?? this.totalPage,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure ?? this.failure,
      refreshTick: refreshTick ?? this.refreshTick,
      markingReadId: clearMarkingReadId
          ? null
          : (markingReadId ?? this.markingReadId),
      markReadFailure: markReadFailure ?? this.markReadFailure,
      markReadFailureTick: markReadFailureTick ?? this.markReadFailureTick,
    );
  }
}
