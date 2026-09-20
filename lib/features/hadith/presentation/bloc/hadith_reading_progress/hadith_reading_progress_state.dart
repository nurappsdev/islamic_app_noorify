import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_progress.dart';

enum HadithReadingProgressStatus { initial, loading, success, failure }

class HadithReadingProgressState {
  const HadithReadingProgressState({
    this.status = HadithReadingProgressStatus.initial,
    this.progress,
    this.failure,
  });

  final HadithReadingProgressStatus status;

  /// The latest progress loaded. Kept when a refresh fails, so the last known
  /// values stay visible.
  final HadithReadingProgress? progress;
  final Failure? failure;

  bool get isLoading =>
      status == HadithReadingProgressStatus.initial ||
      status == HadithReadingProgressStatus.loading;

  /// The category's progress, or null while loading, on failure, or when the
  /// backend has none for it (shown as 0%).
  HadithCategoryProgress? forCategory(String categoryId) =>
      progress?.forCategory(categoryId);
}
