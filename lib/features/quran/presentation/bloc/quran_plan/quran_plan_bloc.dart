import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/quran/data/repositories/quran_plan_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_plan.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_plan_repository.dart';

import 'quran_plan_event.dart';
import 'quran_plan_state.dart';

export 'quran_plan_event.dart';
export 'quran_plan_state.dart';

class QuranPlanBloc extends Bloc<QuranPlanEvent, QuranPlanState> {
  QuranPlanBloc({QuranPlanRepository? repository})
    : _repository = repository ?? QuranPlanRepositoryImpl.shared,
      super(const QuranPlanState()) {
    on<LoadQuranPlans>(_onLoadPlans);
    on<LoadMoreQuranPlans>(_onLoadMorePlans);
    on<CreateQuranPlanSubmitted>(_onCreatePlan);
    on<UpdateQuranPlanStatus>(_onUpdatePlanStatus);
    on<LoadQuranPlanDetails>(_onLoadPlanDetails);
    on<UpdateQuranPlanSubmitted>(_onUpdatePlanSubmitted);
    on<CompleteQuranPlan>(_onCompletePlan);
    on<DeleteQuranPlan>(_onDeletePlan);
    on<LoadPlanAyahs>(_onLoadPlanAyahs);
    on<LoadMorePlanAyahs>(_onLoadMorePlanAyahs);
    on<ChangePlanAyahsFilter>(_onChangePlanAyahsFilter);

    _planChangedSub = _repository.onPlanChanged.listen((_) {
      add(const LoadQuranPlans(forceRefresh: true));
      if (state.selectedPlanDetails != null) {
        add(
          LoadQuranPlanDetails(
            planId: state.selectedPlanDetails!.id,
            forceRefresh: true,
          ),
        );
      }
    });
  }

  final QuranPlanRepository _repository;
  StreamSubscription<void>? _planChangedSub;

  int _activeGeneration = 0;
  int _completedGeneration = 0;

  Future<void> _onLoadPlans(
    LoadQuranPlans event,
    Emitter<QuranPlanState> emit,
  ) async {
    final status = event.status;
    if (status == null || status == 'in_progress') {
      await _loadActivePlans(emit, forceRefresh: event.forceRefresh);
    }
    if (status == null || status == 'completed') {
      await _loadCompletedPlans(emit, forceRefresh: event.forceRefresh);
    }
  }

  Future<void> _loadActivePlans(
    Emitter<QuranPlanState> emit, {
    bool forceRefresh = false,
  }) async {
    final generation = ++_activeGeneration;
    emit(
      state.copyWith(
        activeStatus: QuranPlanLoadStatus.loading,
        clearActiveFailure: true,
        clearDeleteSuccess: true,
        clearCompletedSuccess: true,
      ),
    );

    final result = await _repository.getPlans(
      status: 'in_progress',
      page: 1,
      limit: 10,
      forceRefresh: forceRefresh,
    );

    if (generation != _activeGeneration || emit.isDone) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          activeStatus: QuranPlanLoadStatus.failure,
          activeFailure: failure,
        ),
      ),
      (response) => emit(
        state.copyWith(
          activeStatus: QuranPlanLoadStatus.success,
          activePlans: response.plans,
          activePage: response.meta.page,
          hasMoreActive: response.meta.hasMore,
        ),
      ),
    );
  }

  Future<void> _loadCompletedPlans(
    Emitter<QuranPlanState> emit, {
    bool forceRefresh = false,
  }) async {
    final generation = ++_completedGeneration;
    emit(
      state.copyWith(
        completedStatus: QuranPlanLoadStatus.loading,
        clearCompletedFailure: true,
        clearDeleteSuccess: true,
        clearCompletedSuccess: true,
      ),
    );

    final result = await _repository.getPlans(
      status: 'completed',
      page: 1,
      limit: 10,
      forceRefresh: forceRefresh,
    );

    if (generation != _completedGeneration || emit.isDone) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          completedStatus: QuranPlanLoadStatus.failure,
          completedFailure: failure,
        ),
      ),
      (response) => emit(
        state.copyWith(
          completedStatus: QuranPlanLoadStatus.success,
          completedPlans: response.plans,
          completedPage: response.meta.page,
          hasMoreCompleted: response.meta.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMorePlans(
    LoadMoreQuranPlans event,
    Emitter<QuranPlanState> emit,
  ) async {
    if (event.status == 'in_progress') {
      if (!state.hasMoreActive || state.isLoadingMoreActive) return;
      emit(state.copyWith(isLoadingMoreActive: true));
      final nextPage = state.activePage + 1;
      final result = await _repository.getPlans(
        status: 'in_progress',
        page: nextPage,
        limit: 10,
      );
      if (emit.isDone) return;
      result.fold(
        (_) => emit(state.copyWith(isLoadingMoreActive: false)),
        (response) => emit(
          state.copyWith(
            isLoadingMoreActive: false,
            activePlans: [...state.activePlans, ...response.plans],
            activePage: response.meta.page,
            hasMoreActive: response.meta.hasMore,
          ),
        ),
      );
    } else if (event.status == 'completed') {
      if (!state.hasMoreCompleted || state.isLoadingMoreCompleted) return;
      emit(state.copyWith(isLoadingMoreCompleted: true));
      final nextPage = state.completedPage + 1;
      final result = await _repository.getPlans(
        status: 'completed',
        page: nextPage,
        limit: 10,
      );
      if (emit.isDone) return;
      result.fold(
        (_) => emit(state.copyWith(isLoadingMoreCompleted: false)),
        (response) => emit(
          state.copyWith(
            isLoadingMoreCompleted: false,
            completedPlans: [...state.completedPlans, ...response.plans],
            completedPage: response.meta.page,
            hasMoreCompleted: response.meta.hasMore,
          ),
        ),
      );
    }
  }

  Future<void> _onCreatePlan(
    CreateQuranPlanSubmitted event,
    Emitter<QuranPlanState> emit,
  ) async {
    emit(
      state.copyWith(
        isCreating: true,
        clearCreateFailure: true,
        clearCreatedPlan: true,
      ),
    );

    final result = await _repository.createPlan(event.request);
    if (emit.isDone) return;

    result.fold(
      (failure) =>
          emit(state.copyWith(isCreating: false, createFailure: failure)),
      (plan) {
        emit(state.copyWith(isCreating: false, createdPlan: plan));
        add(const LoadQuranPlans(status: 'in_progress', forceRefresh: true));
      },
    );
  }

  Future<void> _onUpdatePlanStatus(
    UpdateQuranPlanStatus event,
    Emitter<QuranPlanState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdating: true,
        clearUpdateFailure: true,
        clearUpdatedPlan: true,
      ),
    );

    final result = await _repository.updatePlan(
      event.planId,
      UpdateQuranPlanRequest(status: event.status),
    );
    if (emit.isDone) return;

    result.fold(
      (failure) =>
          emit(state.copyWith(isUpdating: false, updateFailure: failure)),
      (plan) {
        emit(state.copyWith(isUpdating: false, updatedPlan: plan));
        add(const LoadQuranPlans(forceRefresh: true));
      },
    );
  }

  Future<void> _onLoadPlanDetails(
    LoadQuranPlanDetails event,
    Emitter<QuranPlanState> emit,
  ) async {
    emit(state.copyWith(isLoadingDetails: true, clearDetailsFailure: true));

    final result = await _repository.getPlanDetails(
      event.planId,
      forceRefresh: event.forceRefresh,
    );
    if (emit.isDone) return;

    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingDetails: false, detailsFailure: failure),
      ),
      (plan) => emit(
        state.copyWith(isLoadingDetails: false, selectedPlanDetails: plan),
      ),
    );
  }

  Future<void> _onUpdatePlanSubmitted(
    UpdateQuranPlanSubmitted event,
    Emitter<QuranPlanState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdating: true,
        clearUpdateFailure: true,
        clearUpdatedPlan: true,
      ),
    );

    final result = await _repository.updatePlan(event.planId, event.request);
    if (emit.isDone) return;

    result.fold(
      (failure) =>
          emit(state.copyWith(isUpdating: false, updateFailure: failure)),
      (plan) {
        emit(
          state.copyWith(
            isUpdating: false,
            updatedPlan: plan,
            selectedPlanDetails: plan,
          ),
        );
        add(const LoadQuranPlans(forceRefresh: true));
      },
    );
  }

  Future<void> _onCompletePlan(
    CompleteQuranPlan event,
    Emitter<QuranPlanState> emit,
  ) async {
    emit(
      state.copyWith(
        isCompleting: true,
        completedSuccess: false,
        clearCompleteFailure: true,
      ),
    );

    final result = await _repository.completePlan(event.planId);
    if (emit.isDone) return;

    result.fold(
      (failure) =>
          emit(state.copyWith(isCompleting: false, completeFailure: failure)),
      (plan) {
        emit(
          state.copyWith(
            isCompleting: false,
            completedSuccess: true,
            selectedPlanDetails: plan,
          ),
        );
      },
    );
  }

  Future<void> _onDeletePlan(
    DeleteQuranPlan event,
    Emitter<QuranPlanState> emit,
  ) async {
    emit(
      state.copyWith(
        isDeleting: true,
        deleteSuccess: false,
        clearDeleteFailure: true,
      ),
    );

    final result = await _repository.deletePlan(event.planId);
    if (emit.isDone) return;

    result.fold(
      (failure) =>
          emit(state.copyWith(isDeleting: false, deleteFailure: failure)),
      (_) {
        final updatedActive = state.activePlans
            .where((p) => p.id != event.planId)
            .toList();
        final updatedCompleted = state.completedPlans
            .where((p) => p.id != event.planId)
            .toList();
        emit(
          state.copyWith(
            isDeleting: false,
            deleteSuccess: true,
            activePlans: updatedActive,
            completedPlans: updatedCompleted,
            clearSelectedPlanDetails:
                state.selectedPlanDetails?.id == event.planId,
          ),
        );
      },
    );
  }

  Future<void> _onLoadPlanAyahs(
    LoadPlanAyahs event,
    Emitter<QuranPlanState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingAyahs: true,
        ayahsFilter: event.filter,
        clearAyahsFailure: true,
      ),
    );

    final result = await _repository.getPlanAyahs(
      event.planId,
      filter: event.filter,
      page: 1,
      limit: 10,
      forceRefresh: event.forceRefresh,
    );
    if (emit.isDone) return;

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingAyahs: false, ayahsFailure: failure)),
      (response) => emit(
        state.copyWith(
          isLoadingAyahs: false,
          planAyahs: response.ayahs,
          planAyahsMeta: response.meta,
        ),
      ),
    );
  }

  Future<void> _onLoadMorePlanAyahs(
    LoadMorePlanAyahs event,
    Emitter<QuranPlanState> emit,
  ) async {
    if (!state.planAyahsMeta.hasMore || state.isLoadingMoreAyahs) return;
    emit(state.copyWith(isLoadingMoreAyahs: true));

    final nextPage = state.planAyahsMeta.page + 1;
    final result = await _repository.getPlanAyahs(
      event.planId,
      filter: state.ayahsFilter,
      page: nextPage,
      limit: 10,
    );
    if (emit.isDone) return;

    result.fold(
      (_) => emit(state.copyWith(isLoadingMoreAyahs: false)),
      (response) => emit(
        state.copyWith(
          isLoadingMoreAyahs: false,
          planAyahs: [...state.planAyahs, ...response.ayahs],
          planAyahsMeta: response.meta,
        ),
      ),
    );
  }

  void _onChangePlanAyahsFilter(
    ChangePlanAyahsFilter event,
    Emitter<QuranPlanState> emit,
  ) {
    if (state.ayahsFilter == event.filter && state.planAyahs.isNotEmpty) return;
    add(
      LoadPlanAyahs(
        planId: event.planId,
        filter: event.filter,
        forceRefresh: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _planChangedSub?.cancel();
    return super.close();
  }
}
