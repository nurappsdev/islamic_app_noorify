import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

enum DuaLoadStatus { initial, loading, success, failure }

class DuaHomeState {
  const DuaHomeState({
    this.status = DuaLoadStatus.initial,
    this.featured = const [],
    this.categories = const [],
    this.error,
  });

  final DuaLoadStatus status;
  final List<DuaFeaturedModel> featured;
  final List<DuaCategoryModel> categories;
  final String? error;

  DuaHomeState copyWith({
    DuaLoadStatus? status,
    List<DuaFeaturedModel>? featured,
    List<DuaCategoryModel>? categories,
    String? error,
  }) => DuaHomeState(
    status: status ?? this.status,
    featured: featured ?? this.featured,
    categories: categories ?? this.categories,
    error: error,
  );
}

/// Loads `/duas/featured` and `/duas/categories` for the Dua dashboard and
/// its "See All" screens — same `load()`-on-create pattern as
/// `ZikrHomeCubit`.
class DuaHomeCubit extends Cubit<DuaHomeState> {
  DuaHomeCubit(this._repository) : super(const DuaHomeState());
  final DuaRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: DuaLoadStatus.loading));
    try {
      final results = await Future.wait([
        _repository.getFeatured(),
        _repository.getCategories(),
      ]);
      final featured = results[0] as List<DuaFeaturedModel>;
      final categories = results[1] as List<DuaCategoryModel>;

      // The `category` embedded in a `/duas/featured` item omits
      // `totalDuasCount`; swap in the full category from `/duas/categories`
      // (matched by id) so the featured card can show a real count.
      final categoryById = {for (final c in categories) c.id: c};
      final enrichedFeatured = [
        for (final item in featured)
          if (categoryById[item.categoryId] case final full?)
            item.withCategory(full)
          else
            item,
      ];

      emit(
        state.copyWith(
          status: DuaLoadStatus.success,
          featured: enrichedFeatured,
          categories: categories,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: DuaLoadStatus.failure, error: '$error'));
    }
  }
}
