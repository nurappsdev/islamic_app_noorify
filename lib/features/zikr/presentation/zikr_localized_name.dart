import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_catalog.dart';

/// The English/Bangla label for a Home Screen Zikr section item (Prayer
/// Zikr 1 & 2), resolved from [ZikrItem.trackingKey] via the app's active
/// language. `null` for any zikr outside that section ([ZikrItem.name] is
/// shown as-is for those, same as before).
String? localizedTrackedZikrName(AppText appText, String? trackingKey) {
  switch (trackingKey) {
    case 'subhanAllah1':
      return appText.zikrNameSubhanAllah;
    case 'alhamdulillah1':
      return appText.zikrNameAlhamdulillah;
    case 'allahuAkbar1':
      return appText.zikrNameAllahuAkbar;
    case 'finalZikr2':
      return appText.zikrNameFinalZikr;
    default:
      return null;
  }
}
