import 'package:islami_app_noorify/core/utils/localized_text.dart';

/// A number together with how it is written in each language, e.g.
/// `{value: 17, bn: "১৭", en: "17"}`.
class LocalizedCount {
  const LocalizedCount({required this.value, required this.text});

  final int value;
  final LocalizedText text;
}

/// One topic of the question bank (`GET /quizzes/categories`).
class QuizCategory {
  const QuizCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.displayOrder,
    required this.totalQuestions,
    required this.isActive,
  });

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final String? iconUrl;
  final int displayOrder;

  /// How many active questions the category holds.
  final LocalizedCount totalQuestions;
  final bool isActive;
}
