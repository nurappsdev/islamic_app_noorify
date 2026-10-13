import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/repositories/dua_repository_impl.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

/// Feature-scoped composition root, same pattern as `zikr_dependencies.dart`.
final DuaRepository duaRepository = DuaRepositoryImpl(
  DuaRemoteDataSourceImpl(),
);
