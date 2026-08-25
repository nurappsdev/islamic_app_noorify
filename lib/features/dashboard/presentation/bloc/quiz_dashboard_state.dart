class QuizDashboardState {
  QuizDashboardState({
    this.selectedPeriod = 0,
    this.showCompetitor = true,
    DateTime? selectedDate,
  }) : selectedDate = selectedDate ?? DateTime.now();

  final int selectedPeriod;
  final bool showCompetitor;
  final DateTime selectedDate;

  QuizDashboardState copyWith({
    int? selectedPeriod,
    bool? showCompetitor,
    DateTime? selectedDate,
  }) {
    return QuizDashboardState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      showCompetitor: showCompetitor ?? this.showCompetitor,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}
