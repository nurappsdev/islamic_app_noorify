import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

enum QuizLoadStatus { initial, loading, success, empty, failure }

class QuizQuestionState {
  const QuizQuestionState({
    this.loadStatus = QuizLoadStatus.initial,
    this.quiz,
    this.currentIndex = 0,
    this.answers = const {},
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
