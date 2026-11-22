import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/entities/promo_banner.dart';

abstract interface class PromoBannerRepository {
  /// The active banners, newest configuration first. Falls back to the last
  /// cached answer when the request fails, so a cold launch or a 500 shows
  /// what was there last time instead of nothing.
  Future<Either<Failure, List<PromoBanner>>> getActiveBanners();

  /// Records a tap. Fire and forget: the caller navigates first and never
  /// waits for this, and a failure here is not worth telling anyone about.
  Future<void> trackClick(String bannerId);
}
