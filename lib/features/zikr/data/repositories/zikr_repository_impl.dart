import 'package:tuhfatul_muslim/features/zikr/data/datasources/zikr_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/domain/repositories/zikr_repository.dart';

class ZikrRepositoryImpl implements ZikrRepository {
  ZikrRepositoryImpl(this._remote);
  final ZikrRemoteDataSource _remote;

  @override
  Future<UserTasbihProfile> getProfile() => _remote.getProfile();
  @override
  Future<List<ZikrRoutine>> getRoutines() => _remote.getRoutines();
  @override
  Future<List<ZikrCatalogItem>> getCatalog() => _remote.getCatalog();
  @override
  Future<ZikrCatalogItem> createCatalog(Map<String, dynamic> body) =>
      _remote.createCatalog(body);
  @override
  Future<ZikrCatalogItem> updateCatalog(String id, Map<String, dynamic> body) =>
      _remote.updateCatalog(id, body);
  @override
  Future<void> deleteCatalog(String id) => _remote.deleteCatalog(id);
  @override
  Future<ZikrRoutine> createRoutine(Map<String, dynamic> body) =>
      _remote.createRoutine(body);
  @override
  Future<ZikrRoutine> updateRoutine(String id, Map<String, dynamic> body) =>
      _remote.updateRoutine(id, body);
  @override
  Future<void> deleteRoutine(String id) => _remote.deleteRoutine(id);
  @override
  Future<UserTasbihProfile> incrementTasbih(Map<String, dynamic> body) =>
      _remote.increment(body);
  @override
  Future<List<ZikrPlan>> getPlans({String? status, String? type}) =>
      _remote.getPlans(status: status, type: type);
  @override
  Future<ZikrPlan> createPlan(Map<String, dynamic> body) =>
      _remote.createPlan(body);
  @override
  Future<ZikrPlan> enrollPlan(String id) => _remote.enrollPlan(id);
  @override
  Future<ZikrPlan> incrementPlan(String id, int countAdded) =>
      _remote.incrementPlan(id, countAdded);
  @override
  Future<void> deletePlan(String id) => _remote.deletePlan(id);
  @override
  Future<TasbihAnalyticsResponse> getAnalytics(String period) =>
      _remote.getAnalytics(period);
  @override
  Future<PaginatedHistory> getHistory({
    required int page,
    required int limit,
  }) => _remote.getHistory(page: page, limit: limit);
}
