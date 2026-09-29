/// One notification (`GET /notifications`).
class NotificationEntity {
  const NotificationEntity({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.readAt,
    required this.sentAt,
    required this.createdAt,
  });

  final String id;

  /// Backend token, e.g. `ADMIN_ANNOUNCEMENT`.
  final String type;

  /// Backend token, e.g. `admin`.
  final String category;
  final String title;
  final String body;

  /// Free-form payload the server attaches, e.g. `{"route": "home"}`.
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? sentAt;
  final DateTime? createdAt;

  /// A copy with [isRead] / [readAt] overridden — used to update one item in
  /// a `NotificationBloc` list in place after `POST .../read` succeeds,
  /// without refetching the page it came from.
  NotificationEntity copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationEntity(
      id: id,
      type: type,
      category: category,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      sentAt: sentAt,
      createdAt: createdAt,
    );
  }
}

/// One page of the notification list (`data` + `meta`).
class NotificationPage {
  const NotificationPage({
    required this.notifications,
    required this.page,
    required this.totalPage,
    required this.unreadCount,
  });

  final List<NotificationEntity> notifications;
  final int page;
  final int totalPage;
  final int unreadCount;

  bool get hasMore => page < totalPage;
}
