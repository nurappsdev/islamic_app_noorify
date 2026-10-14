import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';

abstract interface class DuaRepository {
  Future<List<DuaFeaturedModel>> getFeatured();
  Future<List<DuaCategoryModel>> getCategories();
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  });

  Future<DuaFeaturedModel> getDuaById(String id);

  Future<List<DuaPlan>> getPlans({String? status});
  Future<DuaPlan> createPlan(DuaPlanDraft draft);
  Future<DuaPlanDetail> getPlanDetail(String id);
}
