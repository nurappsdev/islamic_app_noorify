import 'package:flutter/widgets.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
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

/// The English/Bangla label for a "My Created Zikr" / planner item seeded
/// from the catalog's SubhanAllah / Alhamdulillah / Allahu Akbar, resolved
/// from its stored `nameKey` via the app's active language. `null` for a
/// zikr the user typed themselves (its own name is shown as-is).
String? localizedSeedZikrName(AppText appText, String? nameKey) {
  switch (nameKey) {
    case 'subhanAllah':
      return appText.zikrNameSubhanAllah;
    case 'alhamdulillah':
      return appText.zikrNameAlhamdulillah;
    case 'allahuAkbar':
      return appText.zikrNameAllahuAkbar;
    default:
      return null;
  }
}

/// Resolves the known API keys to the app language. User-created names stay
/// exactly as entered because the API does not provide a Bangla translation.
///
/// Matched after stripping everything but letters/digits, so both the
/// catalog's own hyphenated keys (e.g. `la-ilaha-illallah`) and a key
/// derived from a name via `zikrKeyFromName` (e.g. `subhan-allah`, from
/// `"Subhan Allah"`) resolve to the same case.
String localizedZikrNameFromKey(
  AppText appText, {
  required String zikrKey,
  required String fallback,
}) {
  final normalized = zikrKey
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  switch (normalized) {
    case 'subhanallah':
      return appText.zikrNameSubhanAllah;
    case 'alhamdulillah':
      return appText.zikrNameAlhamdulillah;
    case 'allahuakbar':
      return appText.zikrNameAllahuAkbar;
    case 'lailahaillallah':
      return appText.zikrNameLaIlahaIllallah;
    case 'astaghfirullah':
      return appText.zikrNameAstaghfirullah;
    case 'lahawlawalaquwwataillabillah':
      return appText.zikrNameLaHawla;
    case 'salawat':
      return appText.zikrNameSalawat;
    case 'subhanallahiwabihamdihi':
      return appText.zikrNameSubhanAllahiWaBihamdihi;
    default:
      return fallback;
  }
}

String localizedZikrItemName(AppText appText, ZikrItem item) =>
    localizedTrackedZikrName(appText, item.trackingKey) ??
    localizedZikrNameFromKey(
      appText,
      zikrKey: item.zikrKey,
      fallback: item.name,
    );

/// Translates the two fixed prayer-routine titles while leaving a user's own
/// custom routine title untouched.
String localizedRoutineName(BuildContext context, String name) {
  if (context.appLanguage != AppLanguage.bangla) return name;
  switch (name.trim().toLowerCase()) {
    case 'prayer zikr 1':
      return 'নামাজের যিকর ১';
    case 'prayer zikr 2':
      return 'নামাজের যিকর ২';
    default:
      return name;
  }
}

/// The `nameKey` to persist for a zikr picked from the catalog's dropdown
/// (SubhanAllah / Alhamdulillah / Allahu Akbar), matched by its English
/// [ZikrItem.name]. `null` for a custom, user-typed name.
String? zikrNameKeyFor(String name) {
  if (name == ZikrCatalog.subhanAllah.name) return 'subhanAllah';
  if (name == ZikrCatalog.alhamdulillah.name) return 'alhamdulillah';
  if (name == ZikrCatalog.allahuAkbar.name) return 'allahuAkbar';
  return null;
}
