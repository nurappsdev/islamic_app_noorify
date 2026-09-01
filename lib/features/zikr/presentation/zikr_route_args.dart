import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';

/// Arguments for [RouteNames.zikrCounter] — an ordered sequence of zikr the
/// counter walks through, one after another.
class ZikrCounterArgs {
  const ZikrCounterArgs({required this.title, required this.items});

  factory ZikrCounterArgs.fromItem(ZikrItem item) =>
      ZikrCounterArgs(title: item.name, items: [item]);

  factory ZikrCounterArgs.fromPreset(ZikrPreset preset) =>
      ZikrCounterArgs(title: preset.name, items: preset.items);

  factory ZikrCounterArgs.custom({required String name, required int target}) =>
      ZikrCounterArgs(
        title: name,
        items: [
          ZikrItem(
            name: name,
            arabic: '',
            transliteration: name,
            target: target < 1 ? 1 : target,
          ),
        ],
      );

  final String title;
  final List<ZikrItem> items;

  int get totalTarget => items.fold(0, (sum, item) => sum + item.target);

  static const ZikrCounterArgs fallback = ZikrCounterArgs(
    title: 'Zikr',
    items: [ZikrCatalog.subhanAllah],
  );
}
