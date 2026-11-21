import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_plan_detail_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_planner_cubit.dart';

class _DelayedPlansRepository implements DuaRepository {
  final plans = Completer<DuaPlanPage>();
  final planDetail = Completer<DuaPlanDetail>();

  @override
  Future<DuaPlanPage> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
  }) => plans.future;

  @override
  Future<List<DuaFeaturedModel>> getFeatured() => throw UnimplementedError();

  @override
  Future<List<DuaCategoryModel>> getCategories() => throw UnimplementedError();

  @override
  Future<DuaCategoryModel> getCategory(String idOrSlug) =>
      throw UnimplementedError();

  @override
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) => throw UnimplementedError();

  @override
  Future<DuaFeaturedModel> getDuaById(String id) => throw UnimplementedError();

  @override
  Future<DuaPlan> createPlan(DuaPlanDraft draft) => throw UnimplementedError();

  @override
  Future<DuaPlanDetail> getPlanDetail(String id) => planDetail.future;

  @override
  Future<void> editPlan(String id, DuaPlanDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> setPlanReminder(String id, {required bool enabled}) =>
      throw UnimplementedError();
  @override
  Future<void> deletePlan(String id) => throw UnimplementedError();

  @override
  Future<DuaPage> browseDuas({
    String? categoryId,
    String? category,
    String? searchTerm,
    bool? isFeatured,
    int page = 1,
    int limit = 20,
  }) => throw UnimplementedError();
  @override
  Future<DuaFeaturedModel?> getLastRead({String? categoryId}) =>
      throw UnimplementedError();
  @override
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteReadingHistoryItem(String duaId) =>
      throw UnimplementedError();
  @override
  Future<void> clearReadingHistory() => throw UnimplementedError();
  @override
  Future<DuaDailySummary> getReadingSummary({required String date}) =>
      throw UnimplementedError();
  @override
  Future<DuaReadingCalendar> getReadingCalendar({
    int days = 30,
    String? from,
    String? to,
  }) => throw UnimplementedError();
  @override
  Future<DuaReadingDashboard> getReadingDashboard({
    required String timeframe,
    String? date,
  }) => throw UnimplementedError();
  @override
  Future<DuaPlannerToday> getPlannerToday() => throw UnimplementedError();
  @override
  Future<DuaPlanHistory> getPlanHistory(
    String id, {
    String? from,
    String? to,
  }) => throw UnimplementedError();
  @override
  Future<void> addPlanItem(String planId, DuaPlanItemDraft item) =>
      throw UnimplementedError();
  @override
  Future<void> removePlanItem(String planId, String duaId) =>
      throw UnimplementedError();
}

void main() {
  test(
    'ignores a planner response that arrives after the cubit closes',
    () async {
      final repository = _DelayedPlansRepository();
      final cubit = DuaPlannerCubit(repository);

      final loading = cubit.load();
      await cubit.close();
      repository.plans.complete(
        const DuaPlanPage(
          plans: [],
          page: 1,
          limit: 10,
          total: 0,
          totalPage: 1,
        ),
      );

      await loading;
      expect(cubit.isClosed, isTrue);
    },
  );

  test(
    'ignores a plan-detail response that arrives after the cubit closes',
    () async {
      final repository = _DelayedPlansRepository();
      final cubit = DuaPlanDetailCubit(repository, planId: 'plan-1');

      final loading = cubit.load();
      await cubit.close();
      repository.planDetail.complete(
        const DuaPlanDetail(
          id: 'plan-1',
          name: 'Morning plan',
          status: 'in_progress',
          daysOfWeek: [],
          items: [],
        ),
      );

      await loading;
      expect(cubit.isClosed, isTrue);
    },
  );
}
