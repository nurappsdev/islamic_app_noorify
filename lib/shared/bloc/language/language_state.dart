enum AppLanguage { english, bangla }

class LanguageState {
  /// Bangla unless told otherwise: it is the app's default language.
  const LanguageState({this.language = AppLanguage.bangla});

  final AppLanguage language;

  LanguageState copyWith({AppLanguage? language}) {
    return LanguageState(language: language ?? this.language);
  }
}
