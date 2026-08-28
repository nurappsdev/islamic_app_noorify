import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class QuranTranslationState {
  const QuranTranslationState({
    this.surahLang = AppLanguage.english,
    this.ayahOverrides = const {},
    this.loaded = false,
    this.fontSizeMultiplier = 1.0,
  });

  /// Translation language applied to every ayah of the surah.
  final AppLanguage surahLang;

  /// Per-ayah language overrides (ayah number -> language).
  final Map<int, AppLanguage> ayahOverrides;

  /// Whether the persisted preference has been read yet.
  final bool loaded;

  /// Zoom level for Quran and translation text.
  final double fontSizeMultiplier;

  AppLanguage langForAyah(int ayahNo) =>
      ayahOverrides[ayahNo] ?? surahLang;

  QuranTranslationState copyWith({
    AppLanguage? surahLang,
    Map<int, AppLanguage>? ayahOverrides,
    bool? loaded,
    double? fontSizeMultiplier,
  }) {
    return QuranTranslationState(
      surahLang: surahLang ?? this.surahLang,
      ayahOverrides: ayahOverrides ?? this.ayahOverrides,
      loaded: loaded ?? this.loaded,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
    );
  }
}
