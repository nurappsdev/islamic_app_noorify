import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';

enum HadithCategoryStatus { initial, loading, success, failure }

class HadithCategoryState {
  const HadithCategoryState({
    this.status = HadithCategoryStatus.initial,
    this.categories = const [],
    this.failure,
  });

  final HadithCategoryStatus status;
  final List<HadithCategory> categories;
  final Failure? failure;

  bool get isLoading =>
      status == HadithCategoryStatus.initial ||
      status == HadithCategoryStatus.loading;
}
