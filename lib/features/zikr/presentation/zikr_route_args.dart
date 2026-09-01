import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';

/// Arguments for [RouteNames.zikrCounter].
class ZikrCounterArgs {
  const ZikrCounterArgs({
    required this.title,
    required this.arabic,
    required this.target,
  });

  ZikrCounterArgs.fromItem(ZikrItem item)
    : title = item.name,
      arabic = item.arabic,
      target = item.target;

  ZikrCounterArgs.fromPreset(ZikrPreset preset)
    : title = preset.name,
      arabic = preset.items.isNotEmpty ? preset.items.first.arabic : '',
      target = preset.total;

  final String title;
  final String arabic;
  final int target;
}
