import 'package:tuhfatul_muslim/features/notifications/domain/entities/notification_entity.dart';

/// Data-layer representation of [NotificationEntity] that knows how to read
/// the API JSON.
///
/// Expected shape (from `GET /notifications`):
/// ```json
/// {
///   "_id": "6abb9fb40cc2d896edc866f0",
///   "type": "ADMIN_ANNOUNCEMENT",
///   "category": "admin",
///   "title": "...",
///   "body": "...",
///   "data": {"route": "home", "notificationId": "..."},
///   "isRead": false,
///   "readAt": null,
///   "sentAt": "2026-09-29T11:23:33.656Z"
/// }
/// ```
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.category,
    required super.title,
    required super.body,
    required super.data,
    required super.isRead,
    required super.readAt,
    required super.sentAt,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return NotificationModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: data is Map<String, dynamic> ? data : const <String, dynamic>{},
      isRead: json['isRead'] == true,
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? '')?.toLocal(),
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '')?.toLocal(),
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

/// Data-layer representation of [NotificationPage]: the `data` array plus
/// the `meta` object of one `GET /notifications` response.
class NotificationPageModel extends NotificationPage {
  const NotificationPageModel({
    required super.notifications,
    required super.page,
    required super.totalPage,
    required super.unreadCount,
  });

  factory NotificationPageModel.fromJson(
    List<dynamic> data,
    Map<String, dynamic> meta,
  ) {
    return NotificationPageModel(
      notifications: [
        for (final item in data)
          if (item is Map<String, dynamic>) NotificationModel.fromJson(item),
      ],
      page: (meta['page'] as num?)?.toInt() ?? 1,
      totalPage: (meta['totalPage'] as num?)?.toInt() ?? 1,
      unreadCount: (meta['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
