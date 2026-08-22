class QuizDashboardState {
  const QuizDashboardState({
    this.selectedPeriod = 0,
    this.showCompetitor = true,
  });

  final int selectedPeriod;
  final bool showCompetitor;

  QuizDashboardState copyWith({int? selectedPeriod, bool? showCompetitor}) {
    return QuizDashboardState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      showCompetitor: showCompetitor ?? this.showCompetitor,
    );
  }
}
