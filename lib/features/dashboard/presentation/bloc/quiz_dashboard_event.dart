abstract class QuizDashboardEvent {
  const QuizDashboardEvent();
}

/// Fetches the dashboard and the comparison for the selected period and
/// dates; also used by Try Again and to refresh.
class LoadQuizDashboard extends QuizDashboardEvent {
  const LoadQuizDashboard();
}

class SelectPeriod extends QuizDashboardEvent {
  const SelectPeriod(this.period);

  final int period;
}

class DismissCompetitor extends QuizDashboardEvent {
  const DismissCompetitor();
}

class GoToPreviousDate extends QuizDashboardEvent {
  const GoToPreviousDate();
}

class GoToNextDate extends QuizDashboardEvent {
  const GoToNextDate();
}
