import 'package:shared_preferences/shared_preferences.dart';

/// Which translation the hadith screens show beside the Arabic.
///
/// Separate from the app's own language: a reader can keep the app in Bangla
/// and still read the hadiths in English. Only hadiths fetched from the API
/// carry an English text, so an offline book page stays Bangla either way.
enum HadithTranslationLanguage {
  bangla,
  english;

  static HadithTranslationLanguage byName(String? name) =>
      name == english.name ? english : bangla;
}

/// How the hadith list shows its content: which texts are visible, which
/// translation they are read in, and how large they are. Separate from the
/// app-wide profile settings.
class HadithContentSettings {
  const HadithContentSettings({
    this.showArabic = true,
    this.showTranslation = true,
    this.translationLanguage = HadithTranslationLanguage.bangla,
    this.arabicScale = 1.0,
    this.translationScale = 1.0,
  });

  /// The range the font sliders and the reader's pinch gesture allow, the
  /// same reach the Quran reader gives its own text.
  static const minScale = 0.8;
  static const maxScale = 2.5;

  final bool showArabic;
  final bool showTranslation;

  /// The translation the reader picked on the reading-language screen.
  final HadithTranslationLanguage translationLanguage;

  /// Multipliers on the default Arabic / translation font sizes.
  final double arabicScale;
  final double translationScale;

  HadithContentSettings copyWith({
    bool? showArabic,
    bool? showTranslation,
    HadithTranslationLanguage? translationLanguage,
    double? arabicScale,
    double? translationScale,
  }) {
    return HadithContentSettings(
      showArabic: showArabic ?? this.showArabic,
      showTranslation: showTranslation ?? this.showTranslation,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      arabicScale: arabicScale ?? this.arabicScale,
      translationScale: translationScale ?? this.translationScale,
    );
  }
}

/// Persists [HadithContentSettings] in shared preferences.
class HadithContentSettingsStore {
  static const _showArabicKey = 'hadith_show_arabic';
  static const _translationLanguageKey = 'hadith_translation_language';
  static const _showTranslationKey = 'hadith_show_translation';
  static const _arabicScaleKey = 'hadith_arabic_font_scale';
  static const _translationScaleKey = 'hadith_translation_font_scale';

  Future<HadithContentSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return HadithContentSettings(
      showArabic: prefs.getBool(_showArabicKey) ?? true,
      showTranslation: prefs.getBool(_showTranslationKey) ?? true,
      translationLanguage: HadithTranslationLanguage.byName(
        prefs.getString(_translationLanguageKey),
      ),
      arabicScale: prefs.getDouble(_arabicScaleKey) ?? 1.0,
      translationScale: prefs.getDouble(_translationScaleKey) ?? 1.0,
    );
  }

  Future<void> save(HadithContentSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showArabicKey, settings.showArabic);
    await prefs.setBool(_showTranslationKey, settings.showTranslation);
    await prefs.setString(
      _translationLanguageKey,
      settings.translationLanguage.name,
    );
    await prefs.setDouble(_arabicScaleKey, settings.arabicScale);
    await prefs.setDouble(_translationScaleKey, settings.translationScale);
  }
}
