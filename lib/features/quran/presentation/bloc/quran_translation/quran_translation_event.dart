import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

abstract class QuranTranslationEvent {
  const QuranTranslationEvent();
}

/// Load the persisted translation language, falling back to the current app
/// UI language the first time it is used.
class LoadTranslationPreference extends QuranTranslationEvent {
  const LoadTranslationPreference(this.uiFallback);

  final AppLanguage uiFallback;
}

/// Set the translation language for the whole surah. Clears every per-ayah
/// override and is persisted across sessions.
class SetSurahTranslationLang extends QuranTranslationEvent {
  const SetSurahTranslationLang(this.lang);

  final AppLanguage lang;
}

/// Override the translation language for a single ayah (not persisted).
class SetAyahTranslationLang extends QuranTranslationEvent {
  const SetAyahTranslationLang(this.ayahNo, this.lang);

  final int ayahNo;
  final AppLanguage lang;
}
