import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Future<Color> _resolve(
  WidgetTester tester,
  Brightness brightness,
  Color Function(BuildContext) pick,
) async {
  late Color result;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Builder(
        builder: (context) {
          result = pick(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  const samples = [
    Colors.white,
    Colors.black,
    Color(0xFF233021),
    Color(0xFFDDE8AE),
    Color(0xFFA1AD59),
    Color(0xFFDFDE68),
    Color(0xFF5D6B44),
    Color(0x14000000),
  ];

  testWidgets('light mode returns every color unchanged', (tester) async {
    for (final c in samples) {
      expect(
        await _resolve(tester, Brightness.light, (x) => x.pageColor(c)),
        c,
      );
      expect(
        await _resolve(tester, Brightness.light, (x) => x.surfaceColor(c)),
        c,
      );
      expect(await _resolve(tester, Brightness.light, (x) => x.inkColor(c)), c);
      expect(
        await _resolve(tester, Brightness.light, (x) => x.textInkColor(c)),
        c,
      );
      expect(
        await _resolve(tester, Brightness.light, (x) => x.onLightInkColor(c)),
        c,
      );
      expect(
        await _resolve(tester, Brightness.light, (x) => x.lineColor(c)),
        c,
      );
    }
  });

  testWidgets('dark mode uses the palette for known colors', (tester) async {
    Future<Color> dark(Color Function(BuildContext) f) =>
        _resolve(tester, Brightness.dark, f);
    expect(
      await dark((c) => c.pageColor(Colors.white)),
      AppColor.darkBackground,
    );
    expect(
      await dark((c) => c.surfaceColor(Colors.white)),
      AppColor.darkSurface,
    );
    expect(
      await dark((c) => c.surfaceColor(const Color(0xFFDDE8AE))),
      AppColor.darkTint,
    );
    expect(
      await dark((c) => c.inkColor(const Color(0xFF233021))),
      AppColor.darkTextPrimary,
    );
  });

  testWidgets('dark mode keeps brand, accent and white-on-color colors', (
    tester,
  ) async {
    Future<Color> dark(Color Function(BuildContext) f) =>
        _resolve(tester, Brightness.dark, f);
    expect(
      await dark((c) => c.surfaceColor(AppColor.primary)),
      AppColor.primary,
    );
    expect(
      await dark((c) => c.surfaceColor(const Color(0xFFDFDE68))),
      const Color(0xFFDFDE68),
    );
    expect(await dark((c) => c.inkColor(Colors.white)), Colors.white);
  });

  testWidgets('dark ink is readable on dark fills', (tester) async {
    Future<Color> dark(Color Function(BuildContext) f) =>
        _resolve(tester, Brightness.dark, f);
    final page = await dark((c) => c.pageColor(Colors.white));
    final card = await dark((c) => c.surfaceColor(Colors.white));
    final tint = await dark((c) => c.surfaceColor(const Color(0xFFECF0DC)));
    for (final ink in const [
      Color(0xFF283016),
      Color(0xFF2C3320),
      Color(0xFF4C5A34),
      Color(0xFF5D6B44),
      Colors.black,
    ]) {
      final mapped = await dark((c) => c.inkColor(ink));
      for (final bg in [page, card, tint]) {
        expect(
          _contrast(mapped, bg),
          greaterThan(4.5),
          reason: '$ink -> $mapped on $bg',
        );
      }
    }
  });

  testWidgets('dark mode text ink reads as text on dark fills', (tester) async {
    Future<Color> dark(Color Function(BuildContext) f) =>
        _resolve(tester, Brightness.dark, f);
    final page = await dark((c) => c.pageColor(Colors.white));
    final card = await dark((c) => c.surfaceColor(Colors.white));
    // The alarm screens' own text colors, from near-black copy to the time
    // wheel's faded tones. [inkColor] keeps the light ones as they are,
    // which is what [textInkColor] exists to fix.
    for (final ink in const [
      Colors.black,
      Colors.black87,
      Colors.black54,
      Color(0xFF8D9B70),
      Color(0xFF9AA687),
      Color(0xFFBDBDBD),
      Color(0xFFBFC79B),
      Color(0xFFE3E6D3),
    ]) {
      final mapped = await dark((c) => c.textInkColor(ink));
      for (final bg in [page, card]) {
        expect(
          _contrast(Color.alphaBlend(mapped, bg), bg),
          greaterThan(4.5),
          reason: '$ink -> $mapped on $bg',
        );
      }
    }
  });

  testWidgets('dark mode text ink keeps the design\'s emphasis order', (
    tester,
  ) async {
    Future<double> alpha(Color ink) async =>
        (await _resolve(tester, Brightness.dark, (c) => c.textInkColor(ink))).a;
    // Body copy and the brand olive come out at full strength...
    expect(await alpha(Colors.black), 1);
    expect(await alpha(const Color(0xFF8D9B70)), 1);
    // ...while the time wheel's faded neighbours stay the quieter ones.
    expect(
      await alpha(const Color(0xFFBFC79B)),
      lessThan(await alpha(const Color(0xFF8D9B70))),
    );
    expect(
      await alpha(const Color(0xFFE3E6D3)),
      lessThan(await alpha(const Color(0xFFBFC79B))),
    );
  });

  testWidgets('dark mode ink over a surface that stays light goes black', (
    tester,
  ) async {
    Future<Color> dark(Color Function(BuildContext) f) =>
        _resolve(tester, Brightness.dark, f);
    // Surfaces the designs keep light in both themes: the splash artwork,
    // the Hadith intro gradient, the library's collection card and the back
    // button badge the Hadith screens share.
    const lightSurfaces = [
      Color(0xFFF8F8F4),
      Color(0xFFFDFEFB),
      Color(0xFFD8E5BC),
      Color(0xFFE9F1C4),
      Color(0xFFD3E2A0),
      Color(0xFFCBD16B),
      Color(0xFFEDE7A6),
      Color(0xFFDDE8BA),
    ];
    for (final ink in const [
      Color(0xFF4C5346),
      Color(0xFF7D8765),
      Color(0xFF2C3320),
      Color(0xFF303629),
      Color(0xFF84945F),
    ]) {
      final mapped = await dark((c) => c.onLightInkColor(ink));
      expect(mapped, Colors.black, reason: '$ink');
      for (final bg in lightSurfaces) {
        expect(_contrast(mapped, bg), greaterThan(4.5), reason: '$ink on $bg');
      }
    }
    // The point of the helper: [inkColor] would have turned these light.
    for (final ink in const [Color(0xFF7D8765), Color(0xFF84945F)]) {
      final viaInk = await dark((c) => c.inkColor(ink));
      expect(
        _contrast(viaInk, const Color(0xFFD8E5BC)),
        lessThan(4.5),
        reason: 'inkColor is the wrong tool over a light surface',
      );
    }
  });

  testWidgets('alpha is preserved', (tester) async {
    final c = await _resolve(
      tester,
      Brightness.dark,
      (x) => x.inkColor(Colors.black54),
    );
    expect(c.a, closeTo(Colors.black54.a, 0.01));
  });
}
