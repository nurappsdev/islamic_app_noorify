import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'language_bloc.dart';

/// The selected language, for [context].
///
/// Building a widget subscribes to it, so the widget redraws when the language
/// changes. Some code runs outside a build with an outer `context` - a dialog
/// or bottom-sheet builder, a callback, a scroll wheel's item builder that runs
/// during layout - where `context.watch` is not allowed and, in a debug build,
/// throws. There it falls back to a plain read: the right language right now,
/// only without the subscription.
AppLanguage languageOf(BuildContext context) {
  try {
    return context.watch<LanguageBloc>().state.language;
  } on AssertionError {
    return context.read<LanguageBloc>().state.language;
  }
}
