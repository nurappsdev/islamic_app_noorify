import 'package:tuhfatul_muslim/features/zikr/data/datasources/zikr_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/zikr/data/repositories/zikr_repository_impl.dart';
import 'package:tuhfatul_muslim/features/zikr/domain/repositories/zikr_repository.dart';

/// Feature-scoped composition root. Keeping this away from global app setup
/// lets the documented Zikr host coexist with the existing app API host.
final ZikrRepository zikrRepository = ZikrRepositoryImpl(
  ZikrRemoteDataSourceImpl(),
);
