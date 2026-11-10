import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/repositories/notification_repository.dart';

/// `PATCH /notifications/{notificationId}/read`.
///
/// Named without "As" (unlike the bloc's `MarkNotificationAsRead` event) so
/// the two don't collide when both are imported into `notification_bloc.dart`.
class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, Unit>> call(String notificationId) =>
      _repository.markNotificationAsRead(notificationId: notificationId);
}
