abstract class QuizDashboardEvent {
  const QuizDashboardEvent();
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
