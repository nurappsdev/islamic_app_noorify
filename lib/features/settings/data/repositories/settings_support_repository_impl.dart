import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/settings/data/datasources/settings_support_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/app_update_note.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/product_item.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/support_overview.dart';
import 'package:tuhfatul_muslim/features/settings/domain/repositories/settings_support_repository.dart';

class SettingsSupportRepositoryImpl implements SettingsSupportRepository {
  SettingsSupportRepositoryImpl(this._remote);

  final SettingsSupportRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ProductItem>>> getOurProducts() =>
      _guard(() async => await _remote.getOurProducts());

  @override
  Future<Either<Failure, AppUpdateNote>> getNewUpdates() =>
      _guard(() async => await _remote.getNewUpdates());

  @override
  Future<Either<Failure, SupportOverview>> getOverview() =>
      _guard(() async => await _remote.getOverview());

  @override
  Future<Either<Failure, String>> submitTicket({
    required String reason,
    required String description,
  }) => _guard(
    () async =>
        await _remote.submitTicket(reason: reason, description: description),
  );

  @override
  Future<Either<Failure, String>> submitFeedback({
    required int rating,
    required String feedbackText,
  }) => _guard(
    () async => await _remote.submitFeedback(
      rating: rating,
      feedbackText: feedbackText,
    ),
  );

  /// Turns the data layer's exceptions into [Failure]s, so every method here
  /// stays a single line.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
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
