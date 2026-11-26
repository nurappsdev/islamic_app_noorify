import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/app_update_note.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/product_item.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/support_overview.dart';

/// Contract for the Settings extras (`/settings/...`) and the support desk
/// (`/support/...`).
abstract interface class SettingsSupportRepository {
  Future<Either<Failure, List<ProductItem>>> getOurProducts();

  Future<Either<Failure, AppUpdateNote>> getNewUpdates();

  Future<Either<Failure, SupportOverview>> getOverview();

  /// Opens a support ticket; returns the server's message on success.
  Future<Either<Failure, String>> submitTicket({
    required String reason,
    required String description,
  });

  /// Sends a 1-5 star rating with a comment; returns the server's message.
  Future<Either<Failure, String>> submitFeedback({
    required int rating,
    required String feedbackText,
  });
}
