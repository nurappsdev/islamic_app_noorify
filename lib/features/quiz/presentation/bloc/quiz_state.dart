import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';

enum QuizStatus { initial, loading, success, failure }

class QuizState {
  const QuizState({
    this.status = QuizStatus.initial,
    this.attempts = const [],
    this.summary = QuizAttemptSummary.empty,
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
  });

  final QuizStatus status;

  /// The user's attempts, most recent first, across the pages loaded so far.
  final List<QuizAttempt> attempts;

  /// As computed by the server for the first page.
  final QuizAttemptSummary summary;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final Failure? failure;

  QuizState copyWith({
    QuizStatus? status,
    List<QuizAttempt>? attempts,
    QuizAttemptSummary? summary,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return QuizState(
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      summary: summary ?? this.summary,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
