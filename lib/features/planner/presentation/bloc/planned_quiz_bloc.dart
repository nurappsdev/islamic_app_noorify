import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/get_planned_questions.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/submit_planned_quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_fifty_fifty.dart';

enum PlannedQuizLoadStatus { loading, success, empty, failure }

class PlannedQuizState {
  const PlannedQuizState({
    this.loadStatus = PlannedQuizLoadStatus.loading,
    this.questions = const [],
    this.totalQuestions = 0,
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.currentIndex = 0,
    this.answers = const {},
    this.hiddenOptions = const {},
    this.elapsedSeconds = 0,
    this.submissionStatus = QuizSubmissionStatus.idle,
    this.result,
    this.loadFailure,
    this.pageFailure,
    this.submitFailure,
  });

  final PlannedQuizLoadStatus loadStatus;

  /// The pages loaded so far, in the server's order.
  final List<PlannedQuestion> questions;

  /// All the portion's questions, from the server's `meta.total`.
  final int totalQuestions;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentIndex;

  /// The checked option key per question id, kept until submission.
  final Map<String, String> answers;

  /// The option keys the 50/50 lifeline hid, per question id.
  final Map<String, Set<String>> hiddenOptions;
  final int elapsedSeconds;
  final QuizSubmissionStatus submissionStatus;
  final PlannedQuizResult? result;
  final Failure? loadFailure;

  /// The next page could not be fetched; Next retries it.
  final Failure? pageFailure;
  final Failure? submitFailure;

  PlannedQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  String? get selectedAnswer {
    final question = currentQuestion;
    return question == null ? null : answers[question.id];
  }

  /// The lifeline is used at most once per quiz.
  bool get usedFiftyFifty => hiddenOptions.isNotEmpty;

  bool get canUseFiftyFifty =>
      !usedFiftyFifty &&
      !isLocked &&
      (currentQuestion?.options.length ?? 0) > 2;

  List<QuizOption> get visibleOptions {
    final question = currentQuestion;
    if (question == null) return const [];
    final hidden = hiddenOptions[question.id] ?? const {};
    return [
      for (final option in question.options)
        if (!hidden.contains(option.key)) option,
    ];
  }

  bool get isFirstQuestion => currentIndex == 0;

  /// The last question of the whole portion, not only of the loaded pages.
  bool get isLastQuestion => !hasMore && currentIndex >= questions.length - 1;

  bool get isLocked => submissionStatus != QuizSubmissionStatus.idle;

  PlannedQuizState copyWith({
    PlannedQuizLoadStatus? loadStatus,
    List<PlannedQuestion>? questions,
    int? totalQuestions,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentIndex,
    Map<String, String>? answers,
    Map<String, Set<String>>? hiddenOptions,
    int? elapsedSeconds,
    QuizSubmissionStatus? submissionStatus,
    PlannedQuizResult? result,
    Failure? pageFailure,
    bool clearPageFailure = false,
    Failure? submitFailure,
    bool clearSubmitFailure = false,
  }) {
    return PlannedQuizState(
      loadStatus: loadStatus ?? this.loadStatus,
      questions: questions ?? this.questions,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      hiddenOptions: hiddenOptions ?? this.hiddenOptions,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      result: result ?? this.result,
      loadFailure: loadFailure,
      pageFailure: clearPageFailure ? null : (pageFailure ?? this.pageFailure),
      submitFailure: clearSubmitFailure
          ? null
          : (submitFailure ?? this.submitFailure),
    );
  }
}

abstract class PlannedQuizEvent {
  const PlannedQuizEvent();
}

/// Fetches the first page and starts the clock; also used by Try Again.
class LoadPlannedQuestions extends PlannedQuizEvent {
  const LoadPlannedQuestions();
}

class SelectPlannedAnswer extends PlannedQuizEvent {
  const SelectPlannedAnswer(this.optionKey);

  final String optionKey;
}

/// Spends the 50/50 lifeline on the current question.
class UsePlannedFiftyFifty extends PlannedQuizEvent {
  const UsePlannedFiftyFifty();
}

/// Moves on, fetching the next page first when the loaded ones run out.
class NextPlannedQuestion extends PlannedQuizEvent {
  const NextPlannedQuestion();
}

class PreviousPlannedQuestion extends PlannedQuizEvent {
  const PreviousPlannedQuestion();
}

/// Re-reads the clock; also sent when the app returns to the foreground.
class PlannedQuizTicked extends PlannedQuizEvent {
  const PlannedQuizTicked();
}

/// Sends the answers for scoring, or retries a failed submission. Ignored
/// while one is in flight or done.
class SubmitPlannedQuizAttempt extends PlannedQuizEvent {
  const SubmitPlannedQuizAttempt();
}

/// Plays one portion of a started plan. Questions come from the server a page
/// at a time; scoring is entirely the server's.
class PlannedQuizBloc extends Bloc<PlannedQuizEvent, PlannedQuizState> {
  PlannedQuizBloc({
    required this.plan,
    required this.portion,
    required this._getQuestions,
    required this._submit,
    DateTime Function()? clock,
    this._random,
    this.pageSize = 10,
    this.tickInterval = const Duration(seconds: 1),
  }) : _clock = clock ?? DateTime.now,
       super(const PlannedQuizState()) {
    on<LoadPlannedQuestions>(_onLoad);
    on<SelectPlannedAnswer>(_onSelect);
    on<UsePlannedFiftyFifty>(_onFiftyFifty);
    on<NextPlannedQuestion>(_onNext);
    on<PreviousPlannedQuestion>((event, emit) {
      if (state.isLocked || state.isFirstQuestion) return;
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    });
    on<PlannedQuizTicked>((event, emit) {
      if (_startedAt == null || state.isLocked) return;
      final elapsed = _elapsedNow();
      if (elapsed != state.elapsedSeconds) {
        emit(state.copyWith(elapsedSeconds: elapsed));
      }
    });
    on<SubmitPlannedQuizAttempt>(_onSubmit);
  }

  final QuizPlan plan;
  final QuizPlanPortion portion;
  final GetPlannedQuestions _getQuestions;
  final SubmitPlannedQuiz _submit;
  final DateTime Function() _clock;
  final Random? _random;
  final int pageSize;
  final Duration tickInterval;

  Timer? _ticker;
  DateTime? _startedAt;
  int? _submittedElapsed;

  /// Set before the request goes out, so rapid taps cannot submit twice.
  bool _submitInFlight = false;

  Future<void> _onLoad(
    LoadPlannedQuestions event,
    Emitter<PlannedQuizState> emit,
  ) async {
    _stopTimer();
    _startedAt = null;
    _submittedElapsed = null;
    emit(const PlannedQuizState());
    final result = await _getQuestions(
      planId: plan.id,
      portionId: portion.id,
      page: 1,
      limit: pageSize,
    );
    if (isClosed || emit.isDone) return;
    result.fold(
      (failure) => emit(
        PlannedQuizState(
          loadStatus: PlannedQuizLoadStatus.failure,
          loadFailure: failure,
        ),
      ),
      (page) {
        if (page.questions.isEmpty) {
          emit(const PlannedQuizState(loadStatus: PlannedQuizLoadStatus.empty));
          return;
        }
        _startedAt = _clock();
        emit(
          PlannedQuizState(
            loadStatus: PlannedQuizLoadStatus.success,
            questions: page.questions,
            totalQuestions: page.meta.total,
            page: page.meta.page,
            hasMore: page.meta.hasMore,
          ),
        );
        _ticker = Timer.periodic(
          tickInterval,
          (_) => add(const PlannedQuizTicked()),
        );
      },
    );
  }

  void _onSelect(SelectPlannedAnswer event, Emitter<PlannedQuizState> emit) {
    final question = state.currentQuestion;
    if (question == null || state.isLocked) return;
    if (!state.visibleOptions.any((o) => o.key == event.optionKey)) return;
    if (state.answers[question.id] == event.optionKey) return;
    emit(
      state.copyWith(answers: {...state.answers, question.id: event.optionKey}),
    );
  }

  void _onFiftyFifty(
    UsePlannedFiftyFifty event,
    Emitter<PlannedQuizState> emit,
  ) {
    final question = state.currentQuestion;
    if (question == null || !state.canUseFiftyFifty) return;
    final hidden = pickFiftyFiftyRemovals(
      [for (final option in question.options) option.key],
      keep: state.answers[question.id],
      random: _random,
    );
    if (hidden.isEmpty) return;
    emit(state.copyWith(hiddenOptions: {question.id: hidden}));
  }

  Future<void> _onNext(
    NextPlannedQuestion event,
    Emitter<PlannedQuizState> emit,
  ) async {
    if (state.isLocked || state.isLoadingMore || state.isLastQuestion) return;
    if (state.currentIndex + 1 < state.questions.length) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
      return;
    }
    // The loaded pages are used up: fetch the next one, then move on.
    emit(state.copyWith(isLoadingMore: true, clearPageFailure: true));
    final result = await _getQuestions(
      planId: plan.id,
      portionId: portion.id,
      page: state.page + 1,
      limit: pageSize,
    );
    if (emit.isDone) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, pageFailure: failure)),
      (page) {
        final known = state.questions.map((q) => q.id).toSet();
        final fresh = page.questions.where((q) => !known.contains(q.id));
        final questions = [...state.questions, ...fresh];
        emit(
          state.copyWith(
            questions: questions,
            totalQuestions: page.meta.total,
            page: page.meta.page,
            hasMore: page.meta.hasMore,
            isLoadingMore: false,
            currentIndex: state.currentIndex + 1 < questions.length
                ? state.currentIndex + 1
                : state.currentIndex,
          ),
        );
      },
    );
  }

  Future<void> _onSubmit(
    SubmitPlannedQuizAttempt event,
    Emitter<PlannedQuizState> emit,
  ) async {
    if (state.questions.isEmpty ||
        _submitInFlight ||
        state.submissionStatus == QuizSubmissionStatus.submitting ||
        state.submissionStatus == QuizSubmissionStatus.submitted) {
      return;
    }
    _submitInFlight = true;
    _stopTimer();
    final elapsed = _submittedElapsed ??= _elapsedNow();
    emit(
      state.copyWith(
        elapsedSeconds: elapsed,
        submissionStatus: QuizSubmissionStatus.submitting,
        clearSubmitFailure: true,
      ),
    );
    final result = await _submit(
      planId: plan.id,
      portionId: portion.id,
      submission: PlannedQuizSubmission(
        timeSpentSeconds: elapsed,
        used5050Lifeline: state.usedFiftyFifty,
        // Every question; one left unanswered goes as `null`, per the API.
        answers: [
          for (final question in state.questions)
            QuizAnswer(
              questionId: question.id,
              checkedBy: state.answers[question.id],
            ),
        ],
      ),
    );
    _submitInFlight = false;
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: QuizSubmissionStatus.failed,
          submitFailure: failure,
        ),
      ),
      (attempt) => emit(
        state.copyWith(
          submissionStatus: QuizSubmissionStatus.submitted,
          result: attempt,
        ),
      ),
    );
  }

  /// Seconds since the quiz opened, from the wall clock so time spent in the
  /// background counts; capped at the API's one-day maximum.
  int _elapsedNow() {
    final startedAt = _startedAt;
    if (startedAt == null) return 0;
    return _clock().difference(startedAt).inSeconds.clamp(0, 24 * 60 * 60);
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
