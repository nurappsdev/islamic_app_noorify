import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/planner/domain/entities/quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/domain/usecases/abandon_quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/domain/usecases/get_quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/domain/usecases/start_quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/domain/usecases/update_quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/bloc/planner_state.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/quiz_plan_failure_message.dart';

enum QuizPlanDetailStatus { loading, success, failure }

class QuizPlanDetailState {
  const QuizPlanDetailState({
    this.status = QuizPlanDetailStatus.loading,
    this.plan,
    this.failure,
    this.busyAction,
    this.notice,
    this.startedSerial = 0,
  });

  final QuizPlanDetailStatus status;

  /// The server's latest copy of the plan.
  final QuizPlan? plan;

  /// Why the plan could not be loaded.
  final Failure? failure;

  /// The start / edit / abandon request in flight, if any.
  final QuizPlanAction? busyAction;
  final PlannerNotice? notice;

  /// Bumped when a start succeeds, so the screen opens the quiz once.
  final int startedSerial;

  QuizPlanDetailState copyWith({
    QuizPlanDetailStatus? status,
    QuizPlan? plan,
    Failure? failure,
    QuizPlanAction? busyAction,
    bool clearBusy = false,
    PlannerNotice? notice,
    int? startedSerial,
  }) {
    return QuizPlanDetailState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      failure: failure ?? this.failure,
      busyAction: clearBusy ? null : (busyAction ?? this.busyAction),
      notice: notice ?? this.notice,
      startedSerial: startedSerial ?? this.startedSerial,
    );
  }
}

abstract class QuizPlanDetailEvent {
  const QuizPlanDetailEvent();
}

/// Fetches the plan; also used by Try Again and to refresh after a quiz.
class LoadQuizPlanDetail extends QuizPlanDetailEvent {
  const LoadQuizPlanDetail();
}

class StartQuizPlanRequested extends QuizPlanDetailEvent {
  const StartQuizPlanRequested();
}

class UpdateQuizPlanDetailRequested extends QuizPlanDetailEvent {
  const UpdateQuizPlanDetailRequested(this.update);

  final QuizPlanUpdate update;
}

class AbandonQuizPlanDetailRequested extends QuizPlanDetailEvent {
  const AbandonQuizPlanDetailRequested();
}

/// One plan (`GET /quizzes/plans/{id}`), started, edited or abandoned from
/// the server's responses.
class QuizPlanDetailBloc
    extends Bloc<QuizPlanDetailEvent, QuizPlanDetailState> {
  QuizPlanDetailBloc({
    required this.planId,
    required this._getPlan,
    required this._startPlan,
    required this._updatePlan,
    required this._abandonPlan,
  }) : super(const QuizPlanDetailState()) {
    on<LoadQuizPlanDetail>((event, emit) async {
      // A refresh keeps the plan on screen while it reloads.
      if (state.plan == null) emit(const QuizPlanDetailState());
      final result = await _getPlan(planId);
      if (emit.isDone) return;
      result.fold(
        (failure) => emit(
          state.plan == null
              ? QuizPlanDetailState(
                  status: QuizPlanDetailStatus.failure,
                  failure: failure,
                )
              : state.copyWith(
                  notice: PlannerNotice(
                    serial: ++_serial,
                    action: QuizPlanAction.load,
                    failure: failure,
                  ),
                ),
        ),
        (plan) => emit(
          state.copyWith(status: QuizPlanDetailStatus.success, plan: plan),
        ),
      );
    });
    on<StartQuizPlanRequested>(
      (event, emit) =>
          _mutate(emit, QuizPlanAction.start, () => _startPlan(planId)),
    );
    on<UpdateQuizPlanDetailRequested>(
      (event, emit) => _mutate(
        emit,
        QuizPlanAction.update,
        () => _updatePlan(planId, event.update),
      ),
    );
    on<AbandonQuizPlanDetailRequested>(
      (event, emit) =>
          _mutate(emit, QuizPlanAction.abandon, () => _abandonPlan(planId)),
    );
  }

  final String planId;
  final GetQuizPlan _getPlan;
  final StartQuizPlan _startPlan;
  final UpdateQuizPlan _updatePlan;
  final AbandonQuizPlan _abandonPlan;
  int _serial = 0;

  Future<void> _mutate(
    Emitter<QuizPlanDetailState> emit,
    QuizPlanAction action,
    Future<Either<Failure, QuizPlan>> Function() request,
  ) async {
    // One request at a time: repeated taps are ignored.
    if (state.busyAction != null || state.plan == null) return;
    emit(state.copyWith(busyAction: action));
    final result = await request();
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          clearBusy: true,
          notice: PlannerNotice(
            serial: ++_serial,
            action: action,
            failure: failure,
          ),
        ),
      ),
      (plan) => emit(
        state.copyWith(
          plan: plan,
          clearBusy: true,
          notice: PlannerNotice(serial: ++_serial, action: action),
          startedSerial: action == QuizPlanAction.start
              ? state.startedSerial + 1
              : null,
        ),
      ),
    );
  }
}
