import 'package:tuhfatul_muslim/features/quran/domain/surah_summary.dart';

class SurahListState {
  const SurahListState({
    this.isLoading = true,
    this.surahs = const [],
    this.hasError = false,
    this.offline = false,
  });

  final bool isLoading;
  final List<SurahSummary> surahs;
  final bool hasError;

  /// The failure was being offline with nothing stored.
  final bool offline;

  SurahListState copyWith({
    bool? isLoading,
    List<SurahSummary>? surahs,
    bool? hasError,
    bool? offline,
  }) {
    return SurahListState(
      isLoading: isLoading ?? this.isLoading,
      surahs: surahs ?? this.surahs,
      hasError: hasError ?? this.hasError,
      offline: offline ?? this.offline,
    );
  }
}
