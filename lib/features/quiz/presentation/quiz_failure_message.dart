import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// A localized, user-facing message for [failure]. Server and exception text
/// is never shown as-is: the failure's kind and status pick the message.
/// [forAttempt] reads a 404 as "attempt not found".
String quizFailureMessage(
  AppText appText,
  Failure? failure, {
  bool forAttempt = false,
}) {
  if (failure is NetworkFailure) return appText.quizErrorNetwork;
  switch (failure?.statusCode) {
    case 401:
      return appText.quizErrorSession;
    case 403:
      return appText.quizErrorForbidden;
    case 404 when forAttempt:
      return appText.quizErrorNotFound;
    case 400:
      return appText.quizErrorInvalidRange;
    default:
      return appText.quizErrorGeneric;
  }
}
