import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_history_item.dart';

class QuizHistoryModel extends QuizHistoryItem {
  const QuizHistoryModel({
    required super.id,
    required super.title,
    required super.questionCount,
    required super.score,
  });

  factory QuizHistoryModel.fromJson(Map<String, dynamic> json) {
    return QuizHistoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      questionCount: json['questionCount'] as int,
      score: (json['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'questionCount': questionCount,
      'score': score,
    };
  }
}
