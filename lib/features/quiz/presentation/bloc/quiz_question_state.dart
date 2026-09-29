import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';

enum QuizLoadStatus { initial, loading, success, empty, failure }

class QuizQuestionState {
  const QuizQuestionState({
    this.loadStatus = QuizLoadStatus.initial,
    this.quiz,
    this.currentIndex = 0,
    this.answers = const {},
    this.hiddenOptions = const {},
    this.elapsedSeconds = 0,
    this.submissionStatus = QuizSubmissionStatus.idle,
    this.result,
    this.loadErrorMessage,
    this.submitErrorMessage,
  });

  final QuizLoadStatus loadStatus;
  final Quiz? quiz;
  final int currentIndex;

  /// The checked option key per question id, kept locally until submission.
  final Map<String, String> answers;

  /// The option keys the 50/50 lifeline hid, per question id.
  final Map<String, Set<String>> hiddenOptions;
  final int elapsedSeconds;
  final QuizSubmissionStatus submissionStatus;

  /// The server's scoring, once [submissionStatus] is `submitted`.
  final QuizAttemptResult? result;
  final String? loadErrorMessage;
  final String? submitErrorMessage;

  List<QuizQuestion> get questions => quiz?.questions ?? const [];

  QuizQuestion? get currentQuestion =>
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
  bool get isLastQuestion => currentIndex >= questions.length - 1;

  int get timeLimitSeconds => quiz?.timeLimitSeconds ?? 0;
  bool get isTimed => timeLimitSeconds > 0;

  int get remainingSeconds {
    final remaining = timeLimitSeconds - elapsedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  /// Share of the time limit used so far, 0-1.
  double get timeProgress =>
      isTimed ? (elapsedSeconds / timeLimitSeconds).clamp(0, 1).toDouble() : 0;

  /// Once submission starts the answers are final.
  bool get isLocked => submissionStatus != QuizSubmissionStatus.idle;

  QuizQuestionState copyWith({
    QuizLoadStatus? loadStatus,
    Quiz? quiz,
    int? currentIndex,
    Map<String, String>? answers,
    Map<String, Set<String>>? hiddenOptions,
    int? elapsedSeconds,
    QuizSubmissionStatus? submissionStatus,
    QuizAttemptResult? result,
    String? loadErrorMessage,
    String? submitErrorMessage,
    bool clearSubmitError = false,
  }) {
    return QuizQuestionState(
      loadStatus: loadStatus ?? this.loadStatus,
      quiz: quiz ?? this.quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      hiddenOptions: hiddenOptions ?? this.hiddenOptions,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      result: result ?? this.result,
      loadErrorMessage: loadErrorMessage ?? this.loadErrorMessage,
      submitErrorMessage: clearSubmitError
          ? null
          : (submitErrorMessage ?? this.submitErrorMessage),
    );
  }
}
