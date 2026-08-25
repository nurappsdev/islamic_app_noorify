import 'package:islami_app_noorify/features/quran/domain/verse_item.dart';

class VerseReaderState {
  const VerseReaderState({
    this.isLoading = true,
    this.verses = const [],
    this.surahNames = const {},
    this.hasError = false,
  });

  final bool isLoading;
  final List<VerseItem> verses;
  final Map<int, String> surahNames;
  final bool hasError;

  VerseReaderState copyWith({
    bool? isLoading,
    List<VerseItem>? verses,
    Map<int, String>? surahNames,
    bool? hasError,
  }) {
    return VerseReaderState(
      isLoading: isLoading ?? this.isLoading,
      verses: verses ?? this.verses,
      surahNames: surahNames ?? this.surahNames,
      hasError: hasError ?? this.hasError,
    );
  }
}
