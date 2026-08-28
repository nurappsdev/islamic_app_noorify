/// A Quran translation the reader can show under each ayah.
///
/// Two editions are *built in* — served by the existing text pipeline
/// (`SurahDetail.englishAyahs` / `bengaliAyahs`, offline `quran_text.text_en` /
/// `text_bn`) — and are always available. The rest are *downloadable*: their
/// text is pulled per whole edition from `api.quran.com` (`resourceId`) into the
/// local `translation_text` table.
class TranslationEdition {
  const TranslationEdition({
    required this.id,
    required this.name,
    required this.languageName,
    this.resourceId,
  });

  /// Stable identifier used as the storage key and the selected-edition value.
  final String id;

  /// Human name of the edition, e.g. "Taisirul Quran".
  final String name;

  /// Language the edition is written in, e.g. "English", "Bengali".
  final String languageName;

  /// quran.com `/api/v4` translation resource id. `null` for built-ins.
  final int? resourceId;

  bool get isBuiltIn => resourceId == null;
}

const kBuiltInEnglishId = 'english';
const kBuiltInBengaliId = 'bengali';

/// The curated catalog shown in the reader settings.
const kTranslationEditions = <TranslationEdition>[
  TranslationEdition(
    id: kBuiltInEnglishId,
    name: 'Saheeh International',
    languageName: 'English',
  ),
  TranslationEdition(
    id: kBuiltInBengaliId,
    name: 'Bengali',
    languageName: 'Bengali',
  ),
  TranslationEdition(
    id: 'qc161',
    name: 'Taisirul Quran',
    languageName: 'Bengali',
    resourceId: 161,
  ),
  TranslationEdition(
    id: 'qc162',
    name: 'Rawai Al-bayan (Bayaan Foundation)',
    languageName: 'Bengali',
    resourceId: 162,
  ),
  TranslationEdition(
    id: 'qc163',
    name: 'Sheikh Mujibur Rahman',
    languageName: 'Bengali',
    resourceId: 163,
  ),
  TranslationEdition(
    id: 'qc213',
    name: 'Dr. Abu Bakr Muhammad Zakaria',
    languageName: 'Bengali',
    resourceId: 213,
  ),
];

TranslationEdition? translationEditionById(String id) {
  for (final e in kTranslationEditions) {
    if (e.id == id) return e;
  }
  return null;
}

bool isBuiltInEditionId(String id) =>
    id == kBuiltInEnglishId || id == kBuiltInBengaliId;
