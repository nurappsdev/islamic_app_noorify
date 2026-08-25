abstract class PlannerEvent {
  const PlannerEvent();
}

class ShowCompletedPlans extends PlannerEvent {
  const ShowCompletedPlans(this.value);

  final bool value;
}

class AddQuiz extends PlannerEvent {
  const AddQuiz(this.planName);

  final String planName;
}

class AddMoreQuizzes extends PlannerEvent {
  const AddMoreQuizzes();
}
