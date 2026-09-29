import 'package:flutter/widgets.dart';

import 'package:tuhfatul_muslim/core/localization/localized_date_formatter.dart';
import 'package:tuhfatul_muslim/core/localization/localized_number_formatter.dart';
import 'package:tuhfatul_muslim/core/localization/localized_time_formatter.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_context.dart';

/// The formatters for the language that is selected. Reading one in `build`
/// subscribes to the language, so the widget redraws when it changes.
extension LocalizationContext on BuildContext {
  AppLanguage get appLanguage => languageOf(this);

  LocalizedNumberFormatter get localizedNumbers =>
      LocalizedNumberFormatter(appLanguage);

  LocalizedTimeFormatter get localizedTimes =>
      LocalizedTimeFormatter(appLanguage);

  LocalizedDateFormatter get localizedDates =>
      LocalizedDateFormatter(appLanguage);
}
