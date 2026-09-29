import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_plan.dart';

abstract interface class QuranPlanRepository {
  /// Whether a user is currently signed in.
  bool get isSignedIn;

  /// Emits whenever a plan is created, updated or reading is tracked.
  Stream<void> get onPlanChanged;

  /// Creates a new Quran plan on the server.
  Future<Either<Failure, QuranPlan>> createPlan(CreateQuranPlanRequest request);

  /// Retrieves user's Quran plans by status (`in_progress` or `completed`).
  Future<Either<Failure, QuranPlansResponse>> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  });

  /// Updates an existing Quran plan.
  Future<Either<Failure, QuranPlan>> updatePlan(
    String planId,
    UpdateQuranPlanRequest request,
  );

  /// Invalidates cached plans in memory.
  void invalidateCache();
}
