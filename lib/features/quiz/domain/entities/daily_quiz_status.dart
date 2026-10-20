/// The daily quiz's availability, attempt and points status (`GET /quizzes/daily/status`).
class DailyQuizStatus {
  const DailyQuizStatus({
    required this.date,
    this.quizId,
    this.isAvailable = false,
    this.isCompleted = false,
    this.hasCompleted = false,
    this.attemptCount = 0,
    this.pointsEarned = 0,
    this.pointsGained = 0,
    this.quizScore = 0,
    this.maxPoints = 0,
    this.bestScorePercentage = 0,
    this.latestAttemptId,
    this.completedAt,
    this.quizzesPerDay = 1,
    this.completedQuizzes = 0,
    this.nextSequence,
  });

  /// The date of the quiz in `YYYY-MM-DD` format.
  final String date;

  /// The unique identifier of today's quiz.
  final String? quizId;

  /// Whether today's quiz is available to play.
  final bool isAvailable;

  /// Whether the user has completed today's quiz.
  final bool isCompleted;

  /// Alternate completed indicator returned by the API.
  final bool hasCompleted;

  /// Number of times attempted today.
  final int attemptCount;

  /// Points earned by the user for today's quiz.
  final num pointsEarned;

  /// Points gained by the user.
  final num pointsGained;

  /// Quiz score value.
  final num quizScore;

  /// Maximum possible points for this quiz.
  final num maxPoints;

  /// The highest score percentage achieved.
  final num bestScorePercentage;

  /// The ID of the latest attempt if completed.
  final String? latestAttemptId;

  /// When the quiz was completed.
  final DateTime? completedAt;

  /// How many daily quizzes a day has (the amol config's, two by default),
  /// played one after the other.
  final int quizzesPerDay;

  /// How many of today's daily quizzes are done.
  final int completedQuizzes;

  /// Which of today's quizzes is next (1-based); null once all are done.
  final int? nextSequence;

  /// Whether the user has completed today's challenge: every daily quiz.
  bool get completed => isCompleted || hasCompleted;

  /// Some of today's quizzes are done, but not all.
  bool get partlyCompleted => !completed && completedQuizzes > 0;

  /// The points to display to the user.
  num get displayPoints => pointsEarned > 0 ? pointsEarned : pointsGained;
}
