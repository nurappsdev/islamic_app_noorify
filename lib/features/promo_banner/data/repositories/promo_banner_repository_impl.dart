import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/promo_banner/data/datasources/promo_banner_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/promo_banner/data/models/promo_banner_model.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/entities/promo_banner.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/repositories/promo_banner_repository.dart';

class PromoBannerRepositoryImpl implements PromoBannerRepository {
  PromoBannerRepositoryImpl(this._remote);

  final PromoBannerRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<PromoBanner>>> getActiveBanners() async {
    try {
      return Right(await _remote.getActiveBanners());
    } on ServerException catch (e) {
      return _cached(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return _cached(NetworkFailure(e.message));
    } catch (_) {
      return _cached(const UnknownFailure());
    }
  }

  @override
  Future<void> trackClick(String bannerId) => _remote.trackClick(bannerId);

  /// The banners from the last successful call, so a server error or an
  /// offline launch keeps showing what was there rather than collapsing the
  /// section. Only when nothing was ever cached does [failure] come back.
  Future<Either<Failure, List<PromoBanner>>> _cached(Failure failure) async {
    final cached = await PromoBannerRemoteDataSourceImpl.cache.read();
    if (cached != null) {
      try {
        return Right(PromoBannerModel.listFrom(cached['data']));
      } catch (_) {
        // Cached payload no longer parses — fall through to the failure.
      }
    }
    return Left(failure);
  }
}
