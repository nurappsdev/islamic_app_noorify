import 'package:shared_preferences/shared_preferences.dart';

/// How the hadith list shows its content: which texts are visible and how
/// large they are. Separate from the app-wide profile settings.
class HadithContentSettings {
  const HadithContentSettings({
    this.showArabic = true,
    this.showTranslation = true,
    this.arabicScale = 1.0,
    this.translationScale = 1.0,
  });

  static const minScale = 0.8;
  static const maxScale = 1.6;

  final bool showArabic;
  final bool showTranslation;

  /// Multipliers on the default Arabic / translation font sizes.
  final double arabicScale;
  final double translationScale;

  HadithContentSettings copyWith({
    bool? showArabic,
    bool? showTranslation,
    double? arabicScale,
    double? translationScale,
  }) {
    return HadithContentSettings(
      showArabic: showArabic ?? this.showArabic,
      showTranslation: showTranslation ?? this.showTranslation,
      arabicScale: arabicScale ?? this.arabicScale,
      translationScale: translationScale ?? this.translationScale,
    );
  }
}

/// Persists [HadithContentSettings] in shared preferences.
class HadithContentSettingsStore {
  static const _showArabicKey = 'hadith_show_arabic';
  static const _showTranslationKey = 'hadith_show_translation';
  static const _arabicScaleKey = 'hadith_arabic_font_scale';
  static const _translationScaleKey = 'hadith_translation_font_scale';

  Future<HadithContentSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return HadithContentSettings(
      showArabic: prefs.getBool(_showArabicKey) ?? true,
      showTranslation: prefs.getBool(_showTranslationKey) ?? true,
      arabicScale: prefs.getDouble(_arabicScaleKey) ?? 1.0,
      translationScale: prefs.getDouble(_translationScaleKey) ?? 1.0,
    );
  }

  Future<void> save(HadithContentSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showArabicKey, settings.showArabic);
    await prefs.setBool(_showTranslationKey, settings.showTranslation);
    await prefs.setDouble(_arabicScaleKey, settings.arabicScale);
    await prefs.setDouble(_translationScaleKey, settings.translationScale);
  }
}
