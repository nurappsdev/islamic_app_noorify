class DuaSettingsState {
  const DuaSettingsState({
    this.fontSizeMultiplier = 1.0,
    this.showArabic = true,
    this.showTranslation = true,
    this.showTransliteration = true,
  });

  final double fontSizeMultiplier;
  final bool showArabic;
  final bool showTranslation;
  final bool showTransliteration;

  DuaSettingsState copyWith({
    double? fontSizeMultiplier,
    bool? showArabic,
    bool? showTranslation,
    bool? showTransliteration,
  }) {
    return DuaSettingsState(
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      showArabic: showArabic ?? this.showArabic,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
    );
  }
}
