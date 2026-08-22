class AmolDashboardState {
  const AmolDashboardState({required this.selectedPeriod, required this.date});

  final int selectedPeriod;
  final DateTime date;

  AmolDashboardState copyWith({int? selectedPeriod, DateTime? date}) {
    return AmolDashboardState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      date: date ?? this.date,
    );
  }
}
