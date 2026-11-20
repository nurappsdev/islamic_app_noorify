import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

enum DuaCategoryDuasStatus { initial, loading, success, failure }

class DuaCategoryDuasState {
  const DuaCategoryDuasState({
    this.status = DuaCategoryDuasStatus.initial,
    this.duas = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.searchTerm = '',
    this.error,
  });

  final DuaCategoryDuasStatus status;
  final List<DuaFeaturedModel> duas;
  final int total;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final String searchTerm;
  final String? error;

  DuaCategoryDuasState copyWith({
    DuaCategoryDuasStatus? status,
    List<DuaFeaturedModel>? duas,
    int? total,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? searchTerm,
    String? error,
  }) => DuaCategoryDuasState(
    status: status ?? this.status,
    duas: duas ?? this.duas,
    total: total ?? this.total,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    searchTerm: searchTerm ?? this.searchTerm,
    error: error,
  );
}

/// Loads a category's first API page (`/duas?categoryId=…&page=1&limit=20`).
class DuaCategoryDuasCubit extends Cubit<DuaCategoryDuasState> {
  DuaCategoryDuasCubit(this._repository) : super(const DuaCategoryDuasState());

  final DuaRepository _repository;

  static const _limit = 20;

  Future<void> load(DuaCategoryModel category, {String searchTerm = ''}) async {
    if (isClosed) return;
    final query = searchTerm.trim();
    emit(
      state.copyWith(
        status: DuaCategoryDuasStatus.loading,
        searchTerm: query,
        loadingMore: false,
      ),
    );
    try {
      final page = await _repository.browseDuas(
        categoryId: category.id,
        searchTerm: query.isEmpty ? null : query,
        limit: _limit,
      );
      if (isClosed) return;
      final duas = [
        for (final dua in page.items)
          dua.category == null ? dua.withCategory(category) : dua,
      ];
      emit(
        state.copyWith(
          status: DuaCategoryDuasStatus.success,
          duas: duas,
          total: page.total,
          page: page.page,
          hasMore: page.page < page.totalPage,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(status: DuaCategoryDuasStatus.failure, error: '$error'),
      );
    }
  }

  Future<void> loadMore(DuaCategoryModel category) async {
    if (isClosed || state.loadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.browseDuas(
        categoryId: category.id,
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
        page: nextPage,
        limit: _limit,
      );
      if (isClosed) return;
      final more = [
        ...state.duas,
        for (final dua in page.items)
          dua.category == null ? dua.withCategory(category) : dua,
      ];
      emit(
        state.copyWith(
          duas: more,
          page: page.page,
          hasMore: page.page < page.totalPage,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loadingMore: false));
    }
  }
}
