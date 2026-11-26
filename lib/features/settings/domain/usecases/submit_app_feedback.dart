import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/settings/domain/repositories/settings_support_repository.dart';

class SubmitAppFeedbackParams {
  const SubmitAppFeedbackParams({
    required this.rating,
    required this.feedbackText,
  });

  /// 1-5 stars.
  final int rating;
  final String feedbackText;
}

/// Sends a rating and comment (`POST /support/feedback`).
class SubmitAppFeedback {
  const SubmitAppFeedback(this._repository);

  final SettingsSupportRepository _repository;

  Future<Either<Failure, String>> call(SubmitAppFeedbackParams params) =>
      _repository.submitFeedback(
        rating: params.rating,
        feedbackText: params.feedbackText,
      );
}
