import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/entities/notification_entity.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/repositories/notification_repository.dart';

class GetNotifications {
  const GetNotifications(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, NotificationPage>> call({
    int page = 1,
    int limit = 10,
    bool unreadOnly = true,
  }) => _repository.getNotifications(
    page: page,
    limit: limit,
    unreadOnly: unreadOnly,
  );
}
