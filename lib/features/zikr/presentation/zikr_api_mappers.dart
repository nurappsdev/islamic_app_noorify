import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_catalog.dart';

String zikrKeyFromName(String name) => name
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

extension ZikrCatalogItemUiMapper on ZikrCatalogItem {
  ZikrItem toUiItem({int? target}) => ZikrItem(
    name: zikrName,
    arabic: nameArabic,
    transliteration: nameTransliteration.isEmpty
        ? zikrName
        : nameTransliteration,
    target: target ?? defaultTargetCount,
    zikrKey: zikrKeyFromName(zikrName),
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
