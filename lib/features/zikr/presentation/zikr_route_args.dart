import 'package:tuhfatul_muslim/features/zikr/data/zikr_catalog.dart';

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
    // Empty: the screen shows the app's own "Zikr" title.
    title: '',
    items: [ZikrCatalog.subhanAllah],
  );
}

/// In-memory handoff from the counter back to the Home screen. The app route
/// table uses `MaterialPageRoute<void>`, so a typed Navigator pop result is
/// not safe here. This small feature-scoped handoff preserves the completed
/// zikr while Home reloads its API data.
class ZikrCounterCompletion {
  const ZikrCounterCompletion({required this.item, required this.count});

  final ZikrItem item;
  final int count;
}

abstract final class ZikrCounterCompletionStore {
  static ZikrCounterCompletion? _completion;

  static void clear() => _completion = null;

  static void complete(ZikrItem item, int count) {
    _completion = ZikrCounterCompletion(item: item, count: count);
  }

  static ZikrCounterCompletion? consume() {
    final completion = _completion;
    _completion = null;
    return completion;
  }
}
