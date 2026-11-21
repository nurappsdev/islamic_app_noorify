import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';

abstract interface class DuaRepository {
  Future<List<DuaFeaturedModel>> getFeatured();
  Future<List<DuaCategoryModel>> getCategories();
  Future<DuaCategoryModel> getCategory(String idOrSlug);
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  });
  Future<DuaPage> browseDuas({
    String? categoryId,
    String? category,
    String? searchTerm,
    bool? isFeatured,
    int page = 1,
    int limit = 20,
  });

  Future<DuaFeaturedModel> getDuaById(String id);
  Future<DuaFeaturedModel?> getLastRead({String? categoryId});
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  });
  Future<void> deleteReadingHistoryItem(String duaId);
  Future<void> clearReadingHistory();
  Future<DuaDailySummary> getReadingSummary({required String date});
  Future<DuaReadingCalendar> getReadingCalendar({
    int days = 30,
    String? from,
    String? to,
  });
  Future<DuaReadingDashboard> getReadingDashboard({
    required String timeframe,
    String? date,
  });

  Future<DuaPlanPage> getPlans({String? status, int page = 1, int limit = 10});
  Future<DuaPlan> createPlan(DuaPlanDraft draft);
  Future<DuaPlanDetail> getPlanDetail(String id);
  Future<void> editPlan(String id, DuaPlanDraft draft);

  /// Turns the plan's reminder notifications off or back on
  /// (`PATCH /duas/planner/plans/{id}` with only `reminderEnabled`).
  Future<void> setPlanReminder(String id, {required bool enabled});
  Future<void> deletePlan(String id);
  Future<DuaPlannerToday> getPlannerToday();
  Future<DuaPlanHistory> getPlanHistory(String id, {String? from, String? to});
  Future<void> addPlanItem(String planId, DuaPlanItemDraft item);
  Future<void> removePlanItem(String planId, String duaId);
}
