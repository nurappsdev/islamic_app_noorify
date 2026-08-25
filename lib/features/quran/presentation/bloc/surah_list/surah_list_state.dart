import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';

class SurahListState {
  const SurahListState({
    this.isLoading = true,
    this.surahs = const [],
    this.hasError = false,
  });

  final bool isLoading;
  final List<SurahSummary> surahs;
  final bool hasError;

  SurahListState copyWith({
    bool? isLoading,
    List<SurahSummary>? surahs,
    bool? hasError,
  }) {
    return SurahListState(
      isLoading: isLoading ?? this.isLoading,
      surahs: surahs ?? this.surahs,
      hasError: hasError ?? this.hasError,
    );
  }
}
