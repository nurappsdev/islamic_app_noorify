abstract class NotificationEvent {
  const NotificationEvent();
}

/// Loads the first page; also used by "try again" from an error state.
class FetchNotifications extends NotificationEvent {
  const FetchNotifications();
}

/// Appends the next page, when there is one.
class LoadMoreNotifications extends NotificationEvent {
  const LoadMoreNotifications();
}

/// Reloads the first page (pull-to-refresh). Keeps the current list showing
/// if the request fails, so the gesture never wipes an already-visible list.
class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}

/// Marks one notification read (`POST /notifications/{id}/read`) and, on
/// success, flips `isRead` on that item in place — no refetch, pagination
/// untouched. A no-op if the item is already read or already being marked.
class MarkNotificationAsRead extends NotificationEvent {
  const MarkNotificationAsRead(this.notificationId);

  final String notificationId;
}
