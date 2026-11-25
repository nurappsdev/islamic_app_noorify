import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/home/data/home_feature_order_store.dart';

void main() {
  const defaults = ['quran', 'hadith', 'dua', 'quiz', 'zikr', 'asma'];
  final store = HomeFeatureOrderStore.instance;

  setUp(store.reset);

  test('default order until the user moves something', () {
    expect(store.ordered(defaults), defaults);
    expect(store.isCustomized, isFalse);
  });

  test('zikr dropped on the 2nd tile becomes the 2nd tile', () {
    store.moveTo(id: 'zikr', targetId: 'hadith', defaultIds: defaults);
    expect(store.ordered(defaults), [
      'quran',
      'zikr',
      'hadith',
      'dua',
      'quiz',
      'asma',
    ]);
    expect(store.isCustomized, isTrue);
  });

  test('a new feature id joins at the end, a retired one is ignored', () {
    store.moveTo(id: 'zikr', targetId: 'quran', defaultIds: defaults);
    const shipped = ['quran', 'hadith', 'dua', 'quiz', 'zikr', 'tasbih'];
    expect(store.ordered(shipped), [
      'zikr',
      'quran',
      'hadith',
      'dua',
      'quiz',
      'tasbih',
    ]);
  });

  test('dropping a tile on itself changes nothing', () {
    store.moveTo(id: 'dua', targetId: 'dua', defaultIds: defaults);
    expect(store.ordered(defaults), defaults);
  });
}
