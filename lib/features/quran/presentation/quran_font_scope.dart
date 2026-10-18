import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/core/theme/app_typography.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Gives every Quran screen the same typeface the rest of the app uses —
/// Ubuntu for English, Noto Sans Bengali for Bangla — instead of whatever
/// font the pusher's route happened to leave in the theme.
///
/// Wrap each Quran route's page in this: a pushed route doesn't inherit the
/// pusher's theme, while dialogs and bottom sheets capture it themselves.
class QuranFontScope extends StatelessWidget {
  const QuranFontScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageBloc>().state.language;
    final family = appFontFamilyFor(language);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: family),
        primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: family),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: family),
        child: child,
      ),
    );
  }
}

/// A [MaterialPageRoute] whose page sits in a [QuranFontScope].
class QuranPageRoute<T> extends MaterialPageRoute<T> {
  QuranPageRoute({required super.builder, super.settings});

  @override
  Widget buildContent(BuildContext context) =>
      QuranFontScope(child: super.buildContent(context));
}
