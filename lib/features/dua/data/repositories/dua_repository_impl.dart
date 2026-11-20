import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

class DuaRepositoryImpl implements DuaRepository {
  DuaRepositoryImpl(this._remote);
  final DuaRemoteDataSource _remote;

  @override
  Future<List<DuaFeaturedModel>> getFeatured() => _remote.getFeatured();
  @override
  Future<List<DuaCategoryModel>> getCategories() => _remote.getCategories();
  @override
  Future<DuaCategoryModel> getCategory(String idOrSlug) =>
      _remote.getCategory(idOrSlug);
  @override
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) => _remote.getByCategory(categoryId, page: page, limit: limit);

  @override
  Future<DuaPage> browseDuas({
    String? categoryId,
    String? category,
    String? searchTerm,
    bool? isFeatured,
    int page = 1,
    int limit = 20,
  }) => _remote.browseDuas(
    categoryId: categoryId,
    category: category,
    searchTerm: searchTerm,
    isFeatured: isFeatured,
    page: page,
    limit: limit,
  );

  @override
  Future<DuaFeaturedModel> getDuaById(String id) => _remote.getDuaById(id);
  @override
  Future<DuaFeaturedModel?> getLastRead({String? categoryId}) =>
      _remote.getLastRead(categoryId: categoryId);
  @override
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  }) => _remote.getReadingHistory(page: page, limit: limit);
  @override
  Future<void> deleteReadingHistoryItem(String duaId) =>
      _remote.deleteReadingHistoryItem(duaId);
  @override
  Future<void> clearReadingHistory() => _remote.clearReadingHistory();
  @override
  Future<DuaDailySummary> getReadingSummary({required String date}) =>
      _remote.getReadingSummary(date: date);
  @override
  Future<DuaReadingCalendar> getReadingCalendar({
    int days = 30,
    String? from,
    String? to,
  }) => _remote.getReadingCalendar(days: days, from: from, to: to);
  @override
  Future<DuaReadingDashboard> getReadingDashboard({
    required String timeframe,
    String? date,
  }) => _remote.getReadingDashboard(timeframe: timeframe, date: date);

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
  Future<void> setPlanReminder(String id, {required bool enabled}) =>
      _remote.setPlanReminder(id, enabled: enabled);
  @override
  Future<void> deletePlan(String id) => _remote.deletePlan(id);
  @override
  Future<DuaPlannerToday> getPlannerToday() => _remote.getPlannerToday();
  @override
  Future<DuaPlanHistory> getPlanHistory(
    String id, {
    String? from,
    String? to,
  }) => _remote.getPlanHistory(id, from: from, to: to);
  @override
  Future<void> addPlanItem(String planId, DuaPlanItemDraft item) =>
      _remote.addPlanItem(planId, item);
  @override
  Future<void> removePlanItem(String planId, String duaId) =>
      _remote.removePlanItem(planId, duaId);
}
