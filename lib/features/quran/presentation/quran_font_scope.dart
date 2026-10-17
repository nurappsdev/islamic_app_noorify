import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/theme/app_typography.dart';

/// The bundled Bangla typeface for the Quran module
/// (assets/fonts/bangla/LiNiladriNodia-Unicode.ttf, Lipighor Font Foundry).
const quranBanglaFontFamily = 'Li Niladri Nodia';

/// Gives every Quran screen Li Niladri Nodia for Bangla text and the app
/// typeface (Ubuntu) for English, whatever the app language.
///
/// Ubuntu stays the family and Li Niladri Nodia is its fallback: Ubuntu has no
/// Bengali glyphs, so Bangla text (labels, translations, Tafsir, Bengali
/// digits) is drawn in Li Niladri Nodia and Latin text in Ubuntu. Arabic text
/// keeps the font it sets explicitly.
///
/// Wrap each Quran route's page in this: a pushed route doesn't inherit the
/// pusher's theme, while dialogs and bottom sheets capture it themselves.
class QuranFontScope extends StatelessWidget {
  const QuranFontScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const family = appFontFamily;
    const fallback = [quranBanglaFontFamily];
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: family,
          fontFamilyFallback: fallback,
        ),
        primaryTextTheme: theme.primaryTextTheme.apply(
          fontFamily: family,
          fontFamilyFallback: fallback,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: family, fontFamilyFallback: fallback),
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
