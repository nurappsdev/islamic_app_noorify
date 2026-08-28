import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Progress of an in-flight translation-edition download.
class EditionDownloadProgress {
  const EditionDownloadProgress({
    required this.editionId,
    this.done = 0,
    this.total = 0,
    this.failed = false,
  });

  final String editionId;
  final int done;
  final int total;
  final bool failed;

  double? get fraction => total > 0 ? (done / total).clamp(0.0, 1.0) : null;
}

class QuranTranslationState {
  const QuranTranslationState({
    this.surahLang = AppLanguage.english,
    this.ayahOverrides = const {},
    this.loaded = false,
    this.arabicFontScale = 1.0,
    this.translationFontScale = 1.0,
    this.showArabic = true,
    this.showTranslation = true,
    this.selectedEditionId = 'english',
    this.downloadedEditionIds = const {},
    this.editionDownload,
    this.surahEditionText = const {},
    this.editionTextSurahNo,
  });

  /// Translation language applied to every ayah (built-in editions only).
  final AppLanguage surahLang;

  /// Per-ayah language overrides (ayah number -> language). Built-ins only.
  final Map<int, AppLanguage> ayahOverrides;

  /// Whether the persisted preference has been read yet.
  final bool loaded;

  /// Zoom for the Arabic ayah text.
  final double arabicFontScale;

  /// Zoom for the translation text.
  final double translationFontScale;

  /// Whether the Arabic ayah text is shown.
  final bool showArabic;

  /// Whether the translation text is shown.
  final bool showTranslation;

  /// Id of the selected translation edition ('english', 'bengali', 'qc162'...).
  final String selectedEditionId;

  /// Edition ids fully downloaded on this device.
  final Set<String> downloadedEditionIds;

  /// Non-null while an edition download is running (or just failed).
  final EditionDownloadProgress? editionDownload;

  /// Text of the selected (custom) edition for the currently open surah:
  /// ayah number -> text. Empty for built-in editions.
  final Map<int, String> surahEditionText;

  /// Which surah [surahEditionText] belongs to.
  final int? editionTextSurahNo;

  bool get usingCustomEdition =>
      selectedEditionId != 'english' && selectedEditionId != 'bengali';

  AppLanguage langForAyah(int ayahNo) => ayahOverrides[ayahNo] ?? surahLang;

  QuranTranslationState copyWith({
    AppLanguage? surahLang,
    Map<int, AppLanguage>? ayahOverrides,
    bool? loaded,
    double? arabicFontScale,
    double? translationFontScale,
    bool? showArabic,
    bool? showTranslation,
    String? selectedEditionId,
    Set<String>? downloadedEditionIds,
    EditionDownloadProgress? editionDownload,
    bool clearEditionDownload = false,
    Map<int, String>? surahEditionText,
    int? editionTextSurahNo,
  }) {
    return QuranTranslationState(
      surahLang: surahLang ?? this.surahLang,
      ayahOverrides: ayahOverrides ?? this.ayahOverrides,
      loaded: loaded ?? this.loaded,
      arabicFontScale: arabicFontScale ?? this.arabicFontScale,
      translationFontScale: translationFontScale ?? this.translationFontScale,
      showArabic: showArabic ?? this.showArabic,
      showTranslation: showTranslation ?? this.showTranslation,
      selectedEditionId: selectedEditionId ?? this.selectedEditionId,
      downloadedEditionIds: downloadedEditionIds ?? this.downloadedEditionIds,
      editionDownload: clearEditionDownload
          ? null
          : (editionDownload ?? this.editionDownload),
      surahEditionText: surahEditionText ?? this.surahEditionText,
      editionTextSurahNo: editionTextSurahNo ?? this.editionTextSurahNo,
    );
  }
}
