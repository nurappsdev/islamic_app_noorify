import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/domain/repositories/zikr_repository.dart';

enum ZikrLoadStatus { initial, loading, success, failure }

class ZikrHomeState {
  const ZikrHomeState({
    this.status = ZikrLoadStatus.initial,
    this.profile,
    this.routines = const [],
    this.catalog = const [],
    this.error,
  });
  final ZikrLoadStatus status;
  final UserTasbihProfile? profile;
  final List<ZikrRoutine> routines;
  final List<ZikrCatalogItem> catalog;
  final String? error;
  ZikrHomeState copyWith({
    ZikrLoadStatus? status,
    UserTasbihProfile? profile,
    List<ZikrRoutine>? routines,
    List<ZikrCatalogItem>? catalog,
    String? error,
    bool clearError = false,
  }) => ZikrHomeState(
    status: status ?? this.status,
    profile: profile ?? this.profile,
    routines: routines ?? this.routines,
    catalog: catalog ?? this.catalog,
    error: clearError ? null : (error ?? this.error),
  );
}

class ZikrHomeCubit extends Cubit<ZikrHomeState> {
  ZikrHomeCubit(this._repository) : super(const ZikrHomeState());
  final ZikrRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ZikrLoadStatus.loading, clearError: true));
    try {
      // Catalog and routines are deliberately public.  Do not let the
      // protected profile request hide those entries for a signed-out user.
      final publicResults = await Future.wait([
        _repository.getRoutines(),
        _repository.getCatalog(),
      ]);
      UserTasbihProfile? profile;
      String? profileError;
      try {
        profile = await _repository.getProfile();
      } catch (error) {
        profileError = '$error';
      }
      emit(
        state.copyWith(
          status: ZikrLoadStatus.success,
          profile: profile,
          routines: publicResults[0] as List<ZikrRoutine>,
          catalog: publicResults[1] as List<ZikrCatalogItem>,
          error: profileError,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: ZikrLoadStatus.failure, error: '$error'));
    }
  }

  Future<ZikrCatalogItem> createCustomZikr(Map<String, dynamic> body) async {
    final item = await _repository.createCatalog(body);
    emit(state.copyWith(catalog: [...state.catalog, item]));
    return item;
  }
}
