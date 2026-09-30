import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/entities/notification_entity.dart';
import 'package:tuhfatul_muslim/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<Either<Failure, NotificationPage>> getNotifications({
    int page = 1,
    int limit = 10,
    bool unreadOnly = true,
  }) => _guard(
    () => _remote.getNotifications(
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    ),
  );

  @override
  Future<Either<Failure, Unit>> markNotificationAsRead({
    required String notificationId,
  }) => _guard(() async {
    await _remote.markAsRead(notificationId);
    return unit;
  });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
