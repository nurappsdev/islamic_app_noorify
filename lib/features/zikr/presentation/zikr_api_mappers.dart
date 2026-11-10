import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_catalog.dart';

/// Produces the API-safe key required by Zikr routine and plan items.
///
/// The backend accepts only ASCII letters, digits, `_`, and `-`, so deriving
/// a key directly from a Bangla or Arabic display name previously produced an
/// empty string. For such names, encode their Unicode code points as an ASCII
/// slug instead. The key remains deterministic while still meeting the API's
/// 64-character limit.
String zikrKeyFromName(String name) {
  final trimmed = name.trim();
  final latinSlug = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  if (latinSlug.isNotEmpty) return _limitZikrKey(latinSlug);

  final unicodeSlug = trimmed.runes
      .map((rune) => rune.toRadixString(16))
      .join('-');
  return unicodeSlug.isEmpty ? 'general' : _limitZikrKey('zikr-$unicodeSlug');
}

String _limitZikrKey(String value) {
  final limited = value.substring(0, value.length > 64 ? 64 : value.length);
  final withoutTrailingSeparator = limited.replaceFirst(RegExp(r'-+$'), '');
  return withoutTrailingSeparator.isEmpty
      ? 'general'
      : withoutTrailingSeparator;
}

/// The catalog supplies a transliteration for its localized display name.
/// Prefer it to keep familiar keys such as `subhan-allahi-wa-bihamdihi`.
String zikrKeyFromCatalogItem(ZikrCatalogItem item) => zikrKeyFromName(
  item.nameTransliteration.isEmpty ? item.zikrName : item.nameTransliteration,
);

extension ZikrCatalogItemUiMapper on ZikrCatalogItem {
  ZikrItem toUiItem({int? target}) => ZikrItem(
    name: zikrName,
    arabic: nameArabic,
    transliteration: nameTransliteration.isEmpty
        ? zikrName
        : nameTransliteration,
    target: target ?? defaultTargetCount,
    zikrKey: zikrKeyFromCatalogItem(this),
  );
}

extension ZikrRoutineItemUiMapper on ZikrRoutineItem {
  ZikrItem toUiItem({String? routineId, String? planId}) => ZikrItem(
    name: zikrName,
    arabic: nameArabic,
    transliteration: zikrName,
    target: targetCount,
    zikrKey: zikrKey,
    routineId: routineId,
    planId: planId,
  );
}

extension ZikrRoutineUiMapper on ZikrRoutine {
  ZikrPreset toUiPreset() => ZikrPreset(
    id: id,
    name: routineName,
    formula: items.map((item) => item.targetCount).join(' +'),
    items: items.map((item) => item.toUiItem(routineId: id)).toList(),
  );
}
