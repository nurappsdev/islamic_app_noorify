import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

class DuaRepositoryImpl implements DuaRepository {
  DuaRepositoryImpl(this._remote);
  final DuaRemoteDataSource _remote;

  @override
  Future<List<DuaFeaturedModel>> getFeatured() => _remote.getFeatured();
  @override
  Future<List<DuaCategoryModel>> getCategories() => _remote.getCategories();
  @override
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) => _remote.getByCategory(categoryId, page: page, limit: limit);

  @override
  Future<DuaFeaturedModel> getDuaById(String id) => _remote.getDuaById(id);

  @override
  Future<DuaPlanPage> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
  }) => _remote.getPlans(status: status, page: page, limit: limit);
  @override
  Future<DuaPlan> createPlan(DuaPlanDraft draft) => _remote.createPlan(draft);
  @override
  Future<DuaPlanDetail> getPlanDetail(String id) => _remote.getPlanDetail(id);
  @override
  Future<void> editPlan(String id, DuaPlanDraft draft) =>
      _remote.editPlan(id, draft);
  @override
  Future<void> deletePlan(String id) => _remote.deletePlan(id);
}
