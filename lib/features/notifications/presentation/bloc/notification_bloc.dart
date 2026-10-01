import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/notifications/domain/usecases/get_notifications.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

import 'notification_event.dart';
import 'notification_state.dart';

export 'notification_event.dart';
export 'notification_state.dart';

/// The signed-in user's notifications (`GET /notifications`), page by page.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(
    this._getNotifications,
    this._markNotificationRead, {
    this.pageSize = 10,
  }) : super(const NotificationState()) {
    on<FetchNotifications>(_onFetch);
    on<LoadMoreNotifications>(_onLoadMore);
    on<RefreshNotifications>(_onRefresh);
    on<MarkNotificationAsRead>(_onMarkRead);
  }

  final GetNotifications _getNotifications;
  final MarkNotificationRead _markNotificationRead;
  final int pageSize;

  Future<void> _onFetch(
    FetchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    final result = await _getNotifications(page: 1, limit: pageSize);
    result.fold(
      (failure) => emit(
        state.copyWith(status: NotificationStatus.failure, failure: failure),
      ),
      (page) {
        _syncBadge(page.unreadCount);
        emit(
          NotificationState(
            status: NotificationStatus.success,
            notifications: page.notifications,
            page: page.page,
            totalPage: page.totalPage,
            unreadCount: page.unreadCount,
            hasMore: page.hasMore,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMore(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    // Guards against a duplicate request while one is already in flight, and
    // stops once the server says there's no next page.
    if (state.status != NotificationStatus.success ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getNotifications(
      page: state.page + 1,
      limit: pageSize,
    );
    result.fold(
      // The rows already shown stay; scrolling to the end again retries.
      (_) => emit(state.copyWith(isLoadingMore: false)),
      (page) {
        _syncBadge(page.unreadCount);
        emit(
          state.copyWith(
            notifications: [...state.notifications, ...page.notifications],
            page: page.page,
            totalPage: page.totalPage,
            unreadCount: page.unreadCount,
            hasMore: page.hasMore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _onRefresh(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _getNotifications(page: 1, limit: pageSize);
    result.fold(
      // Pull-to-refresh failing shouldn't replace an already-visible list
      // with an error screen; the gesture just settles without change. The
      // bumped tick is still emitted so the caller's `firstWhere` resolves.
      (_) => emit(state.copyWith(refreshTick: state.refreshTick + 1)),
      (page) {
        _syncBadge(page.unreadCount);
        emit(
          state.copyWith(
            status: NotificationStatus.success,
            notifications: page.notifications,
            page: page.page,
            totalPage: page.totalPage,
            unreadCount: page.unreadCount,
            hasMore: page.hasMore,
            refreshTick: state.refreshTick + 1,
          ),
        );
      },
    );
  }

  Future<void> _onMarkRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final index = state.notifications.indexWhere(
      (n) => n.id == event.notificationId,
    );
    // Already read, already loading, or not (no longer) in the list: nothing
    // to do. This mirrors the screen's own tap guard, kept here too so the
    // bloc stays correct even if called from somewhere else.
    if (index == -1 ||
        state.notifications[index].isRead ||
        state.markingReadId == event.notificationId) {
      return;
    }

    emit(state.copyWith(markingReadId: event.notificationId));
    final result = await _markNotificationRead(event.notificationId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          clearMarkingReadId: true,
          markReadResultId: event.notificationId,
          markReadResultFailure: failure,
          markReadResultTick: state.markReadResultTick + 1,
        ),
      ),
      (_) {
        final updated = [
          for (final item in state.notifications)
            item.id == event.notificationId
                ? item.copyWith(isRead: true, readAt: DateTime.now())
                : item,
        ];
        final newUnreadCount = state.unreadCount > 0
            ? state.unreadCount - 1
            : 0;
        _syncBadge(newUnreadCount);
        emit(
          state.copyWith(
            notifications: updated,
            clearMarkingReadId: true,
            unreadCount: newUnreadCount,
            markReadResultId: event.notificationId,
            clearMarkReadResultFailure: true,
            markReadResultTick: state.markReadResultTick + 1,
          ),
        );
      },
    );
  }

  /// Keeps the Home AppBar's badge ([unreadNotificationCountNotifier]) in
  /// sync with whatever this bloc last learned from the server, so opening
  /// the notification list - or marking one read from it - is instantly
  /// reflected on Home without a separate `NotificationBadgeService` fetch.
  void _syncBadge(int unreadCount) {
    unreadNotificationCountNotifier.value = unreadCount;
  }
}
