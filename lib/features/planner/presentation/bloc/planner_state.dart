class PlannerState {
  const PlannerState({
    this.showCompletedPlans = false,
    this.hasAddedQuiz = false,
    this.planName = 'Plan 1',
  });

  final bool showCompletedPlans;
  final bool hasAddedQuiz;
  final String planName;

  PlannerState copyWith({
    bool? showCompletedPlans,
    bool? hasAddedQuiz,
    String? planName,
  }) {
    return PlannerState(
      showCompletedPlans: showCompletedPlans ?? this.showCompletedPlans,
      hasAddedQuiz: hasAddedQuiz ?? this.hasAddedQuiz,
      planName: planName ?? this.planName,
    );
  }
}
