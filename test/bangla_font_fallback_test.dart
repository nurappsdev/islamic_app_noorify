import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/bloc/app_preferences/app_preferences_bloc.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';
import 'package:tuhfatul_muslim/core/theme/dark_theme.dart';
import 'package:tuhfatul_muslim/core/theme/light_theme.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/quran/domain/arabic_font.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_font_scope.dart';
import 'package:tuhfatul_muslim/main.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Bangla is only legible if the face drawing it actually holds Bengali
/// glyphs. The English face has none, and neither do the Arabic Quran faces,
/// so every style the app sets has to name the bundled Bangla faces as its
/// fallback - otherwise Bangla is drawn in whatever the device happens to
/// have, or in empty boxes on a device that has nothing.
void main() {
  test('the Bangla faces sit behind every other face', () {
    expect(appFontFamilyFallback, contains(appFontFamilyBangla));
    expect(appFontFamilyFallback, contains('Noto Sans Bengali Regular'));
  });

  test('both themes carry the fallback, in every text style', () {
    for (final theme in [
      lightTheme(fontFamily: appFontFamily),
      darkTheme(fontFamily: appFontFamily),
    ]) {
      final styles = [
        theme.textTheme.bodyMedium,
        theme.textTheme.titleLarge,
        theme.textTheme.labelSmall,
        theme.primaryTextTheme.bodyMedium,
      ];
      for (final style in styles) {
        expect(
          style?.fontFamilyFallback,
          contains(appFontFamilyBangla),
          reason: '$style',
        );
      }
    }
  });

  test('the selectable Arabic faces fall back to Bangla', () {
    for (final font in kArabicFonts) {
      final applied = font.apply(const TextStyle(fontSize: 20));
      expect(
        applied.fontFamilyFallback,
        contains(appFontFamilyBangla),
        reason: font.id,
      );
    }
  });

  testWidgets('text inherits the fallback in English, where it is needed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppText.load();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LanguageBloc(
              initialLanguage: AppLanguage.english,
              persist: (_) async {},
            ),
          ),
          BlocProvider(create: (_) => AppPreferencesBloc()),
        ],
        child: const MyApp(initialRoute: RouteNames.signIn),
      ),
    );
    await tester.pump();

    // The app wraps its whole navigator in this default style.
    final defaults = tester.widgetList<DefaultTextStyle>(
      find.byType(DefaultTextStyle),
    );
    expect(
      defaults.any(
        (d) =>
            d.style.fontFamily == appFontFamily &&
            (d.style.fontFamilyFallback?.contains(appFontFamilyBangla) ??
                false),
      ),
      isTrue,
      reason: defaults.map((d) => d.style.fontFamily).toList().toString(),
    );
  });

  testWidgets('the Quran screens keep the fallback behind their own face', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppText.load();
    late BuildContext inner;
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LanguageBloc(
          initialLanguage: AppLanguage.english,
          persist: (_) async {},
        ),
        child: MaterialApp(
          home: QuranFontScope(
            child: Builder(
              builder: (context) {
                inner = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      DefaultTextStyle.of(inner).style.fontFamilyFallback,
      contains(appFontFamilyBangla),
    );
    expect(
      Theme.of(inner).textTheme.bodyMedium?.fontFamilyFallback,
      contains(appFontFamilyBangla),
    );
  });

  group('source guard', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    /// A style that names a font but no fallback draws Bangla in whatever
    /// face the device supplies. These few are the exceptions, each because
    /// its style passes through something that adds the fallback itself.
    const allowed = <String>[
      // Every builder's result goes through ArabicFont.apply.
      'lib/features/quran/domain/arabic_font.dart',
      // Arabic-Indic digits only, inside a fixed-size ring.
      'lib/features/quran/presentation/widgets/quran_ayah_marker.dart',
      // Hands the family to lightTheme/darkTheme, which add the fallback.
      'lib/main.dart',
    ];

    test('a named font always has the Bangla faces behind it', () {
      final offenders = <String>[];
      for (final file in dartFiles) {
        final path = file.path;
        if (allowed.any(path.endsWith)) continue;
        final source = file.readAsStringSync();
        for (final match in RegExp('fontFamily:').allMatches(source)) {
          final from = (match.start - 400).clamp(0, source.length);
          final to = (match.end + 400).clamp(0, source.length);
          if (source.substring(from, to).contains('fontFamilyFallback')) {
            continue;
          }
          final line = source.substring(0, match.start).split('\n').length;
          offenders.add('$path:$line');
        }
      }
      expect(offenders, isEmpty);
    });

    test('a painter spells the fallback out, having no theme to inherit', () {
      final offenders = <String>[];
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        if (file.path.endsWith('quran_ayah_marker.dart')) continue;
        for (final match in RegExp('TextPainter\\(').allMatches(source)) {
          final to = (match.end + 1200).clamp(0, source.length);
          final window = source.substring(match.end, to);
          final inline = window.indexOf('style: TextStyle(');
          if (inline == -1) continue; // built from a shared style
          if (window.contains('fontFamilyFallback')) continue;
          final line = source.substring(0, match.start).split('\n').length;
          offenders.add('${file.path}:$line');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
