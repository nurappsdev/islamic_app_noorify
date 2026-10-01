import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// What a Learning request was fetching, to word a 404.
enum LearningResource { categories, articles, article }

/// A localized, user-facing message for a Learning [failure]. Server text is
/// never shown; it only goes to the debug log.
String learningFailureMessage(
  AppText appText,
  Failure? failure,
  LearningResource resource,
) {
  if (kDebugMode && failure != null) {
    debugPrint('Learning ${resource.name} failed: $failure');
  }
  if (failure is NetworkFailure) return appText.quizErrorNetwork;
  switch (failure?.statusCode) {
    case 401:
      return appText.quizErrorSession;
    case 403:
      return appText.quizErrorForbidden;
    case 404:
      return resource == LearningResource.article
          ? appText.learningArticleNotFound
          : appText.learningCategoryNotFound;
    case 400:
    case 422:
      return appText.learningErrorInvalid;
    case 429:
      return appText.learningErrorRateLimit;
    default:
      return appText.quizErrorGeneric;
  }
}
