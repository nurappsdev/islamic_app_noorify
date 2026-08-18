enum AppFontSize { small, medium, large, extraLarge }

double appFontScale(AppFontSize size) {
  switch (size) {
    case AppFontSize.small:
      return 0.85;
    case AppFontSize.medium:
      return 1.0;
    case AppFontSize.large:
      return 1.15;
    case AppFontSize.extraLarge:
      return 1.3;
  }
}

class AppPreferencesState {
  const AppPreferencesState({
    this.fontSize = AppFontSize.medium,
    this.darkThemeEnabled = false,
  });

  final AppFontSize fontSize;
  final bool darkThemeEnabled;

  AppPreferencesState copyWith({
    AppFontSize? fontSize,
    bool? darkThemeEnabled,
  }) {
    return AppPreferencesState(
      fontSize: fontSize ?? this.fontSize,
      darkThemeEnabled: darkThemeEnabled ?? this.darkThemeEnabled,
    );
  }
}
