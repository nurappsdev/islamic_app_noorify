import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_category_model.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

class QuizOptionModel extends QuizOption {
  const QuizOptionModel({required super.key, required super.text});

  static QuizOptionModel? fromJson(Object? json) {
    final map = readMap(json);
    final key = map?['key']?.toString().trim();
    if (map == null || key == null || key.isEmpty) return null;
    return QuizOptionModel(key: key, text: LocalizedText.fromJson(map['text']));
  }

  /// Options that lack a `key` are dropped: there is nothing to submit for them.
  static List<QuizOption> listFromJson(Object? json) => json is List
      ? json.map(fromJson).whereType<QuizOption>().toList()
      : const [];
}

/// `difficulty` arrives as `{key, bn, en}`; a bare `"medium"` is accepted too.
({QuizDifficulty? level, LocalizedText label}) readDifficulty(Object? json) {
  final map = readMap(json);
  if (map != null) {
    return (
      level: QuizDifficulty.fromApi(map['key']),
      label: LocalizedText.fromJson(map),
    );
  }
  final level = QuizDifficulty.fromApi(json);
  return (
    level: level,
    label: level == null
        ? LocalizedText.empty
        : LocalizedText(bn: level.apiValue, en: level.apiValue),
  );
}

class QuizQuestionModel extends QuizQuestion {
  const QuizQuestionModel({
    required super.id,
    required super.categoryId,
    required super.question,
    required super.options,
    required super.difficulty,
    required super.difficultyLabel,
    required super.displayOrder,
    required super.isActive,
  });

  static QuizQuestionModel? fromJson(Object? json) {
    final map = readMap(json);
    final id = readId(map?['id']);
    if (map == null || id == null) return null;
    final difficulty = readDifficulty(map['difficulty']);
    return QuizQuestionModel(
      id: id,
      categoryId: readId(map['categoryId']),
      question: LocalizedText.fromJson(map['question']),
      options: QuizOptionModel.listFromJson(map['options']),
      difficulty: difficulty.level,
      difficultyLabel: difficulty.label,
      displayOrder: readNum(map['displayOrder'])?.toInt(),
      isActive: map['isActive'] != false,
    );
  }
}

class QuizModel extends Quiz {
  const QuizModel({
    required super.source,
    required super.id,
    required super.quizDate,
    required super.category,
    required super.pointsReward,
    required super.timeLimitSeconds,
    required super.totalQuestions,
    required super.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    // Kept in the order served: the server fixes the daily quiz's order when it
    // builds it, and a question's displayOrder is its place in the bank, not
    // in this quiz.
    final questions = (rawQuestions is List ? rawQuestions : const [])
        .map(QuizQuestionModel.fromJson)
        .whereType<QuizQuestionModel>()
        // Inactive questions are not played, nor ones with nothing to pick.
        .where((q) => q.isActive && q.options.isNotEmpty)
        .toList();

    final category = readMap(json['category']);
    return QuizModel(
      source: QuizAttemptType.fromApi(json['source']),
      id: readId(json['id']),
      quizDate: json['quizDate']?.toString(),
      category: category == null ? null : QuizCategoryModel.fromJson(category),
      pointsReward: readNum(json['pointsReward']) ?? 0,
      timeLimitSeconds: readNum(json['timeLimitSeconds'])?.toInt() ?? 0,
      totalQuestions:
          readNum(json['totalQuestions'])?.toInt() ?? questions.length,
      questions: List.unmodifiable(questions),
    );
  }
}
