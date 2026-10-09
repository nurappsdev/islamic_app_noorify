import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';

abstract interface class ZikrRepository {
  Future<UserTasbihProfile> getProfile();
  Future<List<ZikrRoutine>> getRoutines();
  Future<List<ZikrCatalogItem>> getCatalog();
  Future<ZikrCatalogItem> createCatalog(Map<String, dynamic> body);
  Future<ZikrCatalogItem> updateCatalog(String id, Map<String, dynamic> body);
  Future<void> deleteCatalog(String id);
  Future<ZikrRoutine> createRoutine(Map<String, dynamic> body);
  Future<ZikrRoutine> updateRoutine(String id, Map<String, dynamic> body);
  Future<void> deleteRoutine(String id);
  Future<UserTasbihProfile> incrementTasbih(Map<String, dynamic> body);
  Future<List<ZikrPlan>> getPlans({String? status, String? type});
  Future<ZikrPlan> createPlan(Map<String, dynamic> body);
  Future<ZikrPlan> enrollPlan(String id);
  Future<ZikrPlan> incrementPlan(String id, int countAdded);
  Future<void> deletePlan(String id);
  Future<TasbihAnalyticsResponse> getAnalytics(String period);
  Future<PaginatedHistory> getHistory({required int page, required int limit});
}
