import 'package:tuhfatul_muslim/features/quran/domain/juz_summary.dart';

class JuzListState {
  const JuzListState({
    this.isLoading = true,
    this.juzs = const [],
    this.surahNames = const {},
    this.hasError = false,
    this.offline = false,
  });

  final bool isLoading;
  final List<JuzSummary> juzs;
  final Map<int, String> surahNames;
  final bool hasError;

  /// The failure was being offline with nothing stored.
  final bool offline;

  JuzListState copyWith({
    bool? isLoading,
    List<JuzSummary>? juzs,
    Map<int, String>? surahNames,
    bool? hasError,
    bool? offline,
  }) {
    return JuzListState(
      isLoading: isLoading ?? this.isLoading,
      juzs: juzs ?? this.juzs,
      surahNames: surahNames ?? this.surahNames,
      hasError: hasError ?? this.hasError,
      offline: offline ?? this.offline,
    );
  }
}
