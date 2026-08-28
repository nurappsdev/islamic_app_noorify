import 'package:islami_app_noorify/features/quran/domain/translation_edition.dart';
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

/// Updates the Arabic-text zoom (persisted).
class SetArabicFontScale extends QuranTranslationEvent {
  const SetArabicFontScale(this.value);

  final double value;
}

/// Updates the translation-text zoom (persisted).
class SetTranslationFontScale extends QuranTranslationEvent {
  const SetTranslationFontScale(this.value);

  final double value;
}

/// Shows or hides the Arabic ayah text (persisted).
class SetShowArabic extends QuranTranslationEvent {
  const SetShowArabic(this.value);

  final bool value;
}

/// Shows or hides the translation text (persisted).
class SetShowTranslation extends QuranTranslationEvent {
  const SetShowTranslation(this.value);

  final bool value;
}

/// Refresh which downloadable editions are on the device.
class LoadTranslationEditions extends QuranTranslationEvent {
  const LoadTranslationEditions();
}

/// Choose which translation edition the reader shows (persisted).
class SelectTranslationEdition extends QuranTranslationEvent {
  const SelectTranslationEdition(this.editionId);

  final String editionId;
}

/// Download a whole edition (all 114 surahs) for offline use.
class DownloadTranslationEdition extends QuranTranslationEvent {
  const DownloadTranslationEdition(this.edition);

  final TranslationEdition edition;
}

/// Remove a downloaded edition from the device.
class DeleteTranslationEdition extends QuranTranslationEvent {
  const DeleteTranslationEdition(this.editionId);

  final String editionId;
}

/// Load the selected (custom) edition's text for one surah into state.
class LoadSurahEditionText extends QuranTranslationEvent {
  const LoadSurahEditionText(this.surahNo);

  final int surahNo;
}
