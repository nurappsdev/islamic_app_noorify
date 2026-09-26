import 'package:flutter/foundation.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_failure_message.dart';

/// What was being done when a quiz plan request failed.
enum QuizPlanAction { load, create, update, abandon, start, questions, submit }

/// A localized, user-facing message for a quiz plan [failure]. The server's
/// own text stays on the [Failure] (and in the debug log) for debugging; it is
/// only read to tell its 409 conflicts apart, never shown.
String quizPlanFailureMessage(
  AppText appText,
  Failure? failure,
  QuizPlanAction action,
) {
  if (kDebugMode && failure != null) {
    debugPrint('Quiz plan ${action.name} failed: $failure');
  }
  final serverText = failure?.message.toLowerCase() ?? '';
  switch (failure?.statusCode) {
    case 404:
      return appText.planErrorNotFound;
    case 409:
      if (serverText.contains('already completed')) {
        return appText.planErrorPortionDone;
      }
      if (serverText.contains('abandon')) return appText.planErrorAbandoned;
      if (serverText.contains('start')) return appText.planErrorNotStarted;
      return action == QuizPlanAction.submit
          ? appText.planErrorPortionDone
          : appText.planErrorAbandoned;
    case 400 when action == QuizPlanAction.create:
      return appText.planErrorInvalid;
    case 400:
      return appText.quizErrorGeneric;
  }
  // Network, 401 (session), 403 and the rest as the other quiz screens do.
  return quizFailureMessage(appText, failure);
}
