import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/entities/notification_entity.dart';

/// Contract for the notifications API. Every call returns [Right] with the
/// result or [Left] with a typed [Failure].
abstract interface class NotificationRepository {
  /// `GET /notifications?unreadOnly=..&page=N&limit=N`.
  Future<Either<Failure, NotificationPage>> getNotifications({
    int page,
    int limit,
    bool unreadOnly,
  });

  /// `POST /notifications/{notificationId}/read`.
  Future<Either<Failure, Unit>> markNotificationAsRead({
    required String notificationId,
  });
}
