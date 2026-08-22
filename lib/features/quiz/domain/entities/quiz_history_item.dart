/// A completed quiz and the learner's result for it.
class QuizHistoryItem {
  const QuizHistoryItem({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.score,
  });

  final String id;
  final String title;
  final int questionCount;
  final double score;
}
