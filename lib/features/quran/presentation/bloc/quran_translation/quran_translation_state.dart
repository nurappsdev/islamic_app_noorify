import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class QuranTranslationState {
  const QuranTranslationState({
    this.surahLang = AppLanguage.english,
    this.ayahOverrides = const {},
    this.loaded = false,
  });

  /// Translation language applied to every ayah of the surah.
  final AppLanguage surahLang;

  /// Per-ayah language overrides (ayah number -> language).
  final Map<int, AppLanguage> ayahOverrides;

  /// Whether the persisted preference has been read yet.
  final bool loaded;

  AppLanguage langForAyah(int ayahNo) =>
      ayahOverrides[ayahNo] ?? surahLang;

  QuranTranslationState copyWith({
    AppLanguage? surahLang,
    Map<int, AppLanguage>? ayahOverrides,
    bool? loaded,
  }) {
    return QuranTranslationState(
      surahLang: surahLang ?? this.surahLang,
      ayahOverrides: ayahOverrides ?? this.ayahOverrides,
      loaded: loaded ?? this.loaded,
    );
  }
}
