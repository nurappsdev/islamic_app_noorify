import 'package:flutter/widgets.dart';

import 'package:tuhfatul_muslim/core/localization/localized_number_formatter.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_entry.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_context.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// What an [AmolEntry] has tracked today, in the selected language: `"25 min"`
/// / `"১ ঘণ্টা ৫ মিনিট"` for the pillars measured in minutes, `"300 zikr"` for
/// a counted one.
///
/// The API sends its own `totalText` too, but it is only ever as fresh as the
/// last response. This is built from the amount itself, so it still reads
/// correctly with this device's unsent reading projected on top.
String formatAmolEntryAmount(
  AmolEntry entry,
  AppText appText,
  AppLanguage language,
) {
  if (entry.isMinutes) {
    return formatAmolMinutes(entry.amount, appText, language);
  }
  final numbers = LocalizedNumberFormatter(language);
  final amount = numbers.digits(_whole(entry.amount));
  final unit = entry.unitLabel.resolve(language);
  return unit.isEmpty ? amount : '$amount $unit';
}

/// [minutes] as `"25 min"`, or `"1 hr 5 min"` once past the hour.
String formatAmolMinutes(num minutes, AppText appText, AppLanguage language) {
  final total = minutes < 0 ? 0 : minutes.floor();
  final hours = total ~/ 60;
  final remainder = total % 60;
  final text = hours == 0
      ? '$remainder ${appText.minLabel}'
      : '$hours ${appText.hrLabel} $remainder ${appText.minLabel}';
  return LocalizedNumberFormatter(language).digits(text);
}

extension AmolEntryLabelContext on BuildContext {
  /// [formatAmolEntryAmount] in the language this context is showing.
  String amolEntryAmount(AmolEntry entry) =>
      formatAmolEntryAmount(entry, AppText.of(this), languageOf(this));
}

String _whole(num value) =>
    value == value.roundToDouble() ? value.round().toString() : '$value';
