/// One of the user's hadith reading plans (`GET /hadiths/plans`).
class HadithPlan {
  const HadithPlan({
    required this.id,
    required this.name,
    required this.status,
    required this.totalHadiths,
    required this.completedHadiths,
    required this.percentage,
    required this.isCompleted,
    this.targetDays,
  });

  final String id;
  final String name;

  /// `in_progress`, `completed` or `abandoned`.
  final String status;

  /// Days the user aims to finish in; null when the plan has no target.
  final int? targetDays;

  /// Every hadith of the plan's categories / chapters, and how many of them
  /// have been read.
  final int totalHadiths;
  final int completedHadiths;

  /// Read share as the backend reports it, `0..100`.
  final double percentage;
  final bool isCompleted;

  int get remainingHadiths => totalHadiths - completedHadiths;
}

/// One page of `GET /hadiths/plans` plus its pagination `meta`.
class HadithPlanPage {
  const HadithPlanPage({
    required this.plans,
    required this.page,
    required this.totalPage,
    required this.total,
  });

  final List<HadithPlan> plans;
  final int page;
  final int totalPage;
  final int total;

  bool get hasMore => page < totalPage;
}
