import 'package:tuhfatul_muslim/features/promo_banner/data/datasources/promo_banner_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/promo_banner/data/repositories/promo_banner_repository_impl.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/repositories/promo_banner_repository.dart';

/// Feature-scoped composition root, same pattern as `dua_dependencies.dart`.
final PromoBannerRepository promoBannerRepository = PromoBannerRepositoryImpl(
  PromoBannerRemoteDataSourceImpl(),
);
