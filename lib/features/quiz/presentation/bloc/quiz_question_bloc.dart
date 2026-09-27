import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_category_quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_daily_quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/submit_quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_fifty_fifty.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_route_args.dart';

import 'quiz_question_event.dart';
import 'quiz_question_state.dart';

export 'quiz_question_event.dart';
export 'quiz_question_state.dart';

/// Plays one quiz: fetches it, keeps the checked answers locally, runs the
/// clock and submits once. Scoring is entirely the server's.
class QuizQuestionBloc extends Bloc<QuizQuestionEvent, QuizQuestionState> {
  QuizQuestionBloc({
    required this.launch,
    required this._getDailyQuiz,
    required this._getCategoryQuiz,
    required this._submitAttempt,
    DateTime Function()? clock,
    this._random,
    this.tickInterval = const Duration(seconds: 1),
  }) : _clock = clock ?? DateTime.now,
       super(const QuizQuestionState()) {
    on<LoadQuiz>(_onLoad);
    on<SelectAnswer>(_onSelect);
    on<UseFiftyFifty>(_onFiftyFifty);
    on<GoToNextQuestion>(_onNext);
    on<GoToPreviousQuestion>(_onPrevious);
    on<QuizTimerTicked>(_onTick);
    on<SubmitQuiz>(_onSubmit);
  }

  final QuizLaunchArgs launch;
  final GetDailyQuiz _getDailyQuiz;
  final GetCategoryQuiz _getCategoryQuiz;
  final SubmitQuizAttempt _submitAttempt;
  final DateTime Function() _clock;
  final Random? _random;

  /// How often the countdown is re-read from the clock.
  final Duration tickInterval;

  Timer? _ticker;
  DateTime? _startedAt;

  /// The time spent, fixed when the first submission starts so a retry
  /// reports the same duration rather than time spent on the error.
  int? _submittedElapsed;

  /// Set synchronously before the request goes out, so a timer expiry and a
  /// tap arriving together cannot both submit.
  bool _submitInFlight = false;

  Future<void> _onLoad(LoadQuiz event, Emitter<QuizQuestionState> emit) async {
    _stopTimer();
    _startedAt = null;
    _submittedElapsed = null;
    emit(const QuizQuestionState(loadStatus: QuizLoadStatus.loading));

    final Either<Failure, Quiz> result;
    final categoryId = launch.categoryId;
    if (launch.attemptType == QuizAttemptType.daily || categoryId == null) {
      result = await _getDailyQuiz(_clock());
    } else {
      result = await _getCategoryQuiz(
        categoryId: categoryId,
        limit: launch.limit,
        difficulty: launch.difficulty,
      );
    }
    // The screen was left while loading; starting the clock would outlive it.
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        // 404 is how the API says there is nothing to play (no questions yet,
        // or the category is gone), which is not an error to retry.
        failure.statusCode == 404
            ? const QuizQuestionState(loadStatus: QuizLoadStatus.empty)
            : QuizQuestionState(
                loadStatus: QuizLoadStatus.failure,
                loadErrorMessage: failure.message,
              ),
      ),
      (quiz) {
        if (quiz.questions.isEmpty) {
          emit(const QuizQuestionState(loadStatus: QuizLoadStatus.empty));
          return;
        }
        _startedAt = _clock();
        emit(QuizQuestionState(loadStatus: QuizLoadStatus.success, quiz: quiz));
        _ticker = Timer.periodic(
          tickInterval,
          (_) => add(const QuizTimerTicked()),
        );
      },
    );
  }

  void _onSelect(SelectAnswer event, Emitter<QuizQuestionState> emit) {
    final question = state.currentQuestion;
    if (question == null || state.isLocked) return;
    if (!state.visibleOptions.any((option) => option.key == event.optionKey)) {
      return;
    }
    if (state.answers[question.id] == event.optionKey) return;
    emit(
      state.copyWith(answers: {...state.answers, question.id: event.optionKey}),
    );
  }

  void _onFiftyFifty(UseFiftyFifty event, Emitter<QuizQuestionState> emit) {
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

  void _onNext(GoToNextQuestion event, Emitter<QuizQuestionState> emit) {
    if (state.isLocked || state.isLastQuestion) return;
    emit(state.copyWith(currentIndex: state.currentIndex + 1));
  }

  void _onPrevious(
    GoToPreviousQuestion event,
    Emitter<QuizQuestionState> emit,
  ) {
    if (state.isLocked || state.isFirstQuestion) return;
    emit(state.copyWith(currentIndex: state.currentIndex - 1));
  }

  void _onTick(QuizTimerTicked event, Emitter<QuizQuestionState> emit) {
    if (_startedAt == null || state.isLocked) return;
    final elapsed = _elapsedNow();
    if (elapsed != state.elapsedSeconds) {
      emit(state.copyWith(elapsedSeconds: elapsed));
    }
    // Out of time: hand in whatever has been answered.
    if (state.isTimed && elapsed >= state.timeLimitSeconds) {
      _stopTimer();
      add(const SubmitQuiz());
    }
  }

  Future<void> _onSubmit(
    SubmitQuiz event,
    Emitter<QuizQuestionState> emit,
  ) async {
    final quiz = state.quiz;
    if (quiz == null ||
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
        clearSubmitError: true,
      ),
    );

    final submission = QuizAttemptSubmission(
      attemptType: launch.attemptType,
      quizId: launch.attemptType == QuizAttemptType.daily ? quiz.id : null,
      categoryId: launch.attemptType == QuizAttemptType.category
          ? (quiz.category?.id ?? launch.categoryId)
          : null,
      timeSpentSeconds: elapsed,
      used5050Lifeline: state.usedFiftyFifty,
      // Every question is sent; one left unanswered goes as `null`.
      answers: [
        for (final question in quiz.questions)
          QuizAnswer(
            questionId: question.id,
            checkedBy: state.answers[question.id],
          ),
      ],
    );

    final result = await _submitAttempt(submission);
    _submitInFlight = false;
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: QuizSubmissionStatus.failed,
          submitErrorMessage: failure.message,
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

  /// Seconds since the quiz started, read from the wall clock so time spent
  /// in the background counts; capped at the time limit when there is one.
  int _elapsedNow() {
    final startedAt = _startedAt;
    if (startedAt == null) return 0;
    final seconds = _clock().difference(startedAt).inSeconds;
    final limit = state.isTimed ? state.timeLimitSeconds : 24 * 60 * 60;
    return seconds.clamp(0, limit);
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
