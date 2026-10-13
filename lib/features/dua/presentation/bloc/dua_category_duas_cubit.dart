import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

enum DuaCategoryDuasStatus { initial, loading, success, failure }

class DuaCategoryDuasState {
  const DuaCategoryDuasState({
    this.status = DuaCategoryDuasStatus.initial,
    this.duas = const [],
    this.total = 0,
    this.error,
  });

  final DuaCategoryDuasStatus status;
  final List<DuaFeaturedModel> duas;
  final int total;
  final String? error;

  DuaCategoryDuasState copyWith({
    DuaCategoryDuasStatus? status,
    List<DuaFeaturedModel>? duas,
    int? total,
    String? error,
  }) => DuaCategoryDuasState(
    status: status ?? this.status,
    duas: duas ?? this.duas,
    total: total ?? this.total,
    error: error,
  );
}

/// Loads a category's first API page (`/duas?categoryId=…&page=1&limit=20`).
class DuaCategoryDuasCubit extends Cubit<DuaCategoryDuasState> {
  DuaCategoryDuasCubit(this._repository) : super(const DuaCategoryDuasState());

  final DuaRepository _repository;

  Future<void> load(DuaCategoryModel category) async {
    emit(state.copyWith(status: DuaCategoryDuasStatus.loading));
    try {
      final page = await _repository.getByCategory(category.id);
      final duas = [
        for (final dua in page.items)
          dua.category == null ? dua.withCategory(category) : dua,
      ];
      emit(
        state.copyWith(
          status: DuaCategoryDuasStatus.success,
          duas: duas,
          total: page.total,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: DuaCategoryDuasStatus.failure, error: '$error'),
      );
    }
  }
}
