abstract class QuizQuestionEvent {
  const QuizQuestionEvent();
}

class SelectAnswer extends QuizQuestionEvent {
  const SelectAnswer(this.answerIndex);

  final int answerIndex;
}
