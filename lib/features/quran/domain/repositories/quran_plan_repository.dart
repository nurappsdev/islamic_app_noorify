import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_plan.dart';

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

  /// Retrieves detailed information for a specific plan.
  Future<Either<Failure, QuranPlan>> getPlanDetails(
    String planId, {
    bool forceRefresh = false,
  });

  /// Updates an existing Quran plan.
  Future<Either<Failure, QuranPlan>> updatePlan(
    String planId,
    UpdateQuranPlanRequest request,
  );

  /// Completes an existing Quran plan on the server.
  Future<Either<Failure, QuranPlan>> completePlan(String planId);

  /// Retrieves paginated list of ayahs for a plan with read status.
  Future<Either<Failure, PaginatedQuranPlanAyahs>> getPlanAyahs(
    String planId, {
    String filter = 'all',
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  });

  /// Deletes or deactivates a plan on the server.
  Future<Either<Failure, void>> deletePlan(String planId);

  /// Invalidates cached plans and details in memory.
  void invalidateCache();
}
