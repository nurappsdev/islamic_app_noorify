import 'package:flutter/widgets.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_category.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_route_args.dart';
import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';

/// Opens today's quiz. Playing needs an account, so a guest is asked to log in.
Future<void> openDailyQuiz(BuildContext context) async {
  if (!await requireLogin(context, feature: AuthFeatures.quiz) ||
      !context.mounted) {
    return;
  }
  await Navigator.of(
    context,
  ).pushNamed(RouteNames.quizQuestion, arguments: const QuizLaunchArgs.daily());
}

/// Opens a practice quiz drawn from [category].
Future<void> openCategoryQuiz(
  BuildContext context,
  QuizCategory category,
) async {
  if (!await requireLogin(context, feature: AuthFeatures.quiz) ||
      !context.mounted) {
    return;
  }
  await Navigator.of(context).pushNamed(
    RouteNames.quizQuestion,
    arguments: QuizLaunchArgs.category(category),
  );
}

/// Opens the question-by-question review of a finished attempt.
Future<void> openQuizAttemptReview(BuildContext context, String attemptId) {
  return Navigator.of(
    context,
  ).pushNamed(RouteNames.quizAttemptReview, arguments: attemptId);
}
