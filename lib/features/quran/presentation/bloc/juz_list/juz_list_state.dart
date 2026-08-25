import 'package:islami_app_noorify/features/quran/domain/juz_summary.dart';

class JuzListState {
  const JuzListState({
    this.isLoading = true,
    this.juzs = const [],
    this.surahNames = const {},
    this.hasError = false,
  });

  final bool isLoading;
  final List<JuzSummary> juzs;
  final Map<int, String> surahNames;
  final bool hasError;

  JuzListState copyWith({
    bool? isLoading,
    List<JuzSummary>? juzs,
    Map<int, String>? surahNames,
    bool? hasError,
  }) {
    return JuzListState(
      isLoading: isLoading ?? this.isLoading,
      juzs: juzs ?? this.juzs,
      surahNames: surahNames ?? this.surahNames,
      hasError: hasError ?? this.hasError,
    );
  }
}
