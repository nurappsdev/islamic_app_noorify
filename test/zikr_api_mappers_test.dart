import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_api_mappers.dart';

void main() {
  test('creates a non-empty, API-safe key for a Bangla Zikr name', () {
    final key = zikrKeyFromName('বিহামদিহী');

    expect(key, isNotEmpty);
    expect(key.length, lessThanOrEqualTo(64));
    expect(key, matches(RegExp(r'^[a-z0-9_-]+$')));
  });

  test('uses a catalog transliteration for a localized display name', () {
    const item = ZikrCatalogItem(
      id: 'bihamdihi',
      zikrName: 'বিহামদিহী',
      nameArabic: '',
      nameTransliteration: 'Subhan Allahi wa bihamdihi',
      defaultTargetCount: 100,
    );

    expect(zikrKeyFromCatalogItem(item), 'subhan-allahi-wa-bihamdihi');
  });
}
