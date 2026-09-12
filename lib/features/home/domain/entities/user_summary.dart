/// The greeting/streak/badge summary shown at the top of the Home dashboard.
class UserSummary {
  const UserSummary({
    required this.fullName,
    required this.greetingText,
    this.avatarUrl,
    this.currentStreakDays = 0,
    this.totalPointsToday = 0,
    this.maxDailyPoints = 0,
    this.percentageToday = 0,
    this.currentBadgeName,
    this.globalRank = 0,
    this.kiblahAngle,
  });

  final String fullName;
  final String greetingText;
  final String? avatarUrl;
  final int currentStreakDays;
  final num totalPointsToday;
  final num maxDailyPoints;
  final num percentageToday;
  final String? currentBadgeName;
  final int globalRank;
  final String? kiblahAngle;
}
