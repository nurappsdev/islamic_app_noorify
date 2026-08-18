enum AppLanguage { english, bangla }

class LanguageState {
  const LanguageState({this.language = AppLanguage.english});

  final AppLanguage language;

  LanguageState copyWith({AppLanguage? language}) {
    return LanguageState(language: language ?? this.language);
  }
}
