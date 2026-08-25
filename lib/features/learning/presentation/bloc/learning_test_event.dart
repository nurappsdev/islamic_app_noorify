abstract class LearningTestEvent {
  const LearningTestEvent();
}

class ToggleAnswer extends LearningTestEvent {
  const ToggleAnswer(this.answerIndex);

  final int answerIndex;
}
