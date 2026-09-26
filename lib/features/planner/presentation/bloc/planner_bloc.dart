import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/abandon_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/get_quiz_plans.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/update_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/presentation/quiz_plan_failure_message.dart';

import 'planner_event.dart';
import 'planner_state.dart';

export 'planner_event.dart';
export 'planner_state.dart';

/// The user's quiz plans (`GET /quizzes/plans`), page by page, with the edits
/// and abandons made from the list applied from the server's responses.
class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  PlannerBloc({
    required this._getPlans,
    required this._updatePlan,
    required this._abandonPlan,
    this.pageSize = 10,
  }) : super(const PlannerState()) {
    on<LoadQuizPlans>(_onLoad);
    on<LoadMoreQuizPlans>(_onLoadMore);
    on<ShowCompletedPlans>((event, emit) {
      if (state.showCompletedPlans != event.value) {
        emit(state.copyWith(showCompletedPlans: event.value));
      }
    });
    on<QuizPlanChanged>((event, emit) => emit(_withPlan(event.plan)));
    on<UpdateQuizPlanRequested>(
      (event, emit) => _mutate(
        emit,
        event.planId,
        QuizPlanAction.update,
        () => _updatePlan(event.planId, event.update),
      ),
    );
    on<AbandonQuizPlanRequested>(
      (event, emit) => _mutate(
        emit,
        event.planId,
        QuizPlanAction.abandon,
        () => _abandonPlan(event.planId),
      ),
    );
  }

  final GetQuizPlans _getPlans;
  final UpdateQuizPlan _updatePlan;
  final AbandonQuizPlan _abandonPlan;
  final int pageSize;

  int _serial = 0;

  /// Bumped per refresh, so an older page cannot land on a newer list.
  int _generation = 0;

  Future<void> _onLoad(LoadQuizPlans event, Emitter<PlannerState> emit) async {
    final generation = ++_generation;
    // A refresh keeps showing the plans it has; only a first load spins.
    emit(
      PlannerState(
        showCompletedPlans: state.showCompletedPlans,
        status: state.plans.isEmpty ? PlannerStatus.loading : state.status,
        plans: state.plans,
        page: state.page,
        hasMore: state.hasMore,
        busyPlanIds: state.busyPlanIds,
      ),
    );
    final result = await _getPlans(page: 1, limit: pageSize);
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) => emit(
        PlannerState(
          showCompletedPlans: state.showCompletedPlans,
          status: PlannerStatus.failure,
          plans: state.plans,
          failure: failure,
          busyPlanIds: state.busyPlanIds,
        ),
      ),
      (page) => emit(
        PlannerState(
          showCompletedPlans: state.showCompletedPlans,
          status: PlannerStatus.success,
          plans: page.plans,
          page: page.meta.page,
          hasMore: page.meta.hasMore,
          busyPlanIds: state.busyPlanIds,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreQuizPlans event,
    Emitter<PlannerState> emit,
  ) async {
    if (state.status != PlannerStatus.success ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getPlans(page: state.page + 1, limit: pageSize);
    if (generation != _generation || emit.isDone) return;
    result.fold(
      // The plans already shown stay; scrolling to the end again retries.
      (_) => emit(state.copyWith(isLoadingMore: false)),
      (page) {
        final known = state.plans.map((p) => p.id).toSet();
        emit(
          state.copyWith(
            // A plan created meanwhile can shift one onto the next page.
            plans: [
              ...state.plans,
              ...page.plans.where((p) => !known.contains(p.id)),
            ],
            page: page.meta.page,
            hasMore: page.meta.hasMore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _mutate(
    Emitter<PlannerState> emit,
    String planId,
    QuizPlanAction action,
    Future<Either<Failure, QuizPlan>> Function() request,
  ) async {
    if (state.busyPlanIds.contains(planId)) return;
    emit(state.copyWith(busyPlanIds: {...state.busyPlanIds, planId}));
    final result = await request();
    if (emit.isDone) return;
    final busy = {...state.busyPlanIds}..remove(planId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          busyPlanIds: busy,
          notice: PlannerNotice(
            serial: ++_serial,
            action: action,
            failure: failure,
          ),
        ),
      ),
      (plan) => emit(
        _withPlan(plan).copyWith(
          busyPlanIds: busy,
          notice: PlannerNotice(serial: ++_serial, action: action),
        ),
      ),
    );
  }

  /// [plan] in place of its old copy, or first when it is new.
  PlannerState _withPlan(QuizPlan plan) {
    final index = state.plans.indexWhere((p) => p.id == plan.id);
    final plans = [...state.plans];
    if (index == -1) {
      plans.insert(0, plan);
    } else {
      plans[index] = plan;
    }
    return state.copyWith(plans: plans);
  }
}
