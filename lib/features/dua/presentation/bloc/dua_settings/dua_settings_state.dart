class DuaSettingsState {
  const DuaSettingsState({
    this.arabicFontSize = 20.0,
    this.translationFontSize = 12.0,
    this.showArabic = true,
    this.showTranslation = true,
    this.showTransliteration = true,
    this.showNarration = true,
    this.showReference = true,
  });

  final double arabicFontSize;
  final double translationFontSize;
  final bool showArabic;
  final bool showTranslation;
  final bool showTransliteration;

  /// Narration/context card (design `devImg/img_20.png`'s "Hadith
  /// Background & Context" toggle).
  final bool showNarration;

  /// Reference/Authentic-Hadith card (design `devImg/img_20.png`'s
  /// "Reference & Chain (Sanad)" toggle).
  final bool showReference;

  DuaSettingsState copyWith({
    double? arabicFontSize,
    double? translationFontSize,
    bool? showArabic,
    bool? showTranslation,
    bool? showTransliteration,
    bool? showNarration,
    bool? showReference,
  }) {
    return DuaSettingsState(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      showArabic: showArabic ?? this.showArabic,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showNarration: showNarration ?? this.showNarration,
      showReference: showReference ?? this.showReference,
    );
  }
}
