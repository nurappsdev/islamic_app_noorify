import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

class DuaRepositoryImpl implements DuaRepository {
  DuaRepositoryImpl(this._remote);
  final DuaRemoteDataSource _remote;

  @override
  Future<List<DuaFeaturedModel>> getFeatured() => _remote.getFeatured();
  @override
  Future<List<DuaCategoryModel>> getCategories() => _remote.getCategories();
}
