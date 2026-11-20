import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_planner_cubit.dart';

class _DelayedPlansRepository implements DuaRepository {
  final plans = Completer<DuaPlanPage>();

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
  Future<DuaPlanDetail> getPlanDetail(String id) => throw UnimplementedError();

  @override
  Future<void> editPlan(String id, DuaPlanDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deletePlan(String id) => throw UnimplementedError();
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
}
