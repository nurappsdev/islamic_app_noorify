import 'package:flutter/material.dart';

import '../utils/app_color.dart';

/// Turns the colors the screens were designed with into their dark-mode
/// counterparts.
///
/// In light mode every method returns its argument unchanged, so the design
/// is exactly what it always was. In dark mode a color is mapped by its role:
///
/// * [pageColor] / [surfaceColor] – fills: light backgrounds become deep
///   green-black surfaces; mid and dark fills (the olive brand color, buttons)
///   are kept.
/// * [inkColor] – text and icons: dark ink becomes light; mid and light ink
///   (brand green, white on a colored button) is kept.
/// * [lineColor] – borders and dividers.
///
/// Colors that the palette already defines (see [AppPalette]) map to those
/// exact dark values; anything else is derived from its hue.
extension ThemeColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// A screen background.
  Color pageColor(Color color) =>
      _isDark ? DarkColorMapper.fill(color, page: true) : color;

  /// A card, sheet, chip or button background.
  Color surfaceColor(Color color) =>
      _isDark ? DarkColorMapper.fill(color) : color;

  /// A text, icon or other foreground color.
  Color inkColor(Color color) => _isDark ? DarkColorMapper.ink(color) : color;

  /// A border or divider color.
  Color lineColor(Color color) => _isDark ? DarkColorMapper.line(color) : color;
}

abstract final class DarkColorMapper {
  /// Olive hue used when a light neutral (white, grey) is darkened.
  static const _neutralHue = 80.0;

  /// Fills at least this colorful (max - min channel) are accents, kept as is.
  static const _vividChroma = 0.40;

  static double _chroma(Color c) =>
      [c.r, c.g, c.b].reduce((a, b) => a > b ? a : b) -
      [c.r, c.g, c.b].reduce((a, b) => a < b ? a : b);

  static const _fillExact = <int, Color>{
    0xFFDDE8AE: AppColor.darkTint,
    0xFFF7F8E8: AppColor.darkTintSoft,
    0xFFE8EBC9: AppColor.darkAvatar,
    0xFFE4E8C8: AppColor.darkBorder,
    0xFFFFF4F4: AppColor.darkDangerSurface,
    0xFFFFD8D8: AppColor.darkDangerTint,
    0xFFE3ECC5: AppColor.darkShimmerBase,
    0xFFF6F9EC: AppColor.darkShimmerHighlight,
    0xFFE0E0E0: AppColor.darkProgressTrack,
  };

  static const _inkExact = <int, Color>{
    0xFF233021: AppColor.darkTextPrimary,
    0xFF1F2B1C: AppColor.darkTextStrong,
    0xFF000000: AppColor.darkTextPrimary,
  };

  static Color fill(Color c, {bool page = false}) {
    if (c.a == 0) return c;
    final hsl = HSLColor.fromColor(c);
    // Dark and mid fills stay, and so do vivid accents (the yellow-green
    // buttons, red badges), which read well on both backgrounds.
    if (hsl.lightness < 0.62 || _chroma(c) >= _vividChroma) return c;
    final opaque = c.withAlpha(0xFF).toARGB32();
    if (opaque == 0xFFFFFFFF) {
      return (page ? AppColor.darkBackground : AppColor.darkSurface).withValues(
        alpha: c.a,
      );
    }
    final exact = _fillExact[opaque];
    if (exact != null) return exact.withValues(alpha: c.a);
    return _darken(hsl, floor: page ? 0.07 : 0.10, maxSaturation: 0.35);
  }

  static Color line(Color c) {
    if (c.a == 0) return c;
    final hsl = HSLColor.fromColor(c);
    if (hsl.lightness < 0.55) return c;
    final opaque = c.withAlpha(0xFF).toARGB32();
    if (opaque == 0xFFFFFFFF)
      return AppColor.darkSurface.withValues(alpha: c.a);
    final exact = _fillExact[opaque];
    if (exact != null) return exact.withValues(alpha: c.a);
    return _darken(hsl, floor: 0.17, maxSaturation: 0.30);
  }

  static Color ink(Color c) {
    if (c.a == 0) return c;
    final hsl = HSLColor.fromColor(c);
    if (hsl.lightness > 0.5) return c;
    final exact = _inkExact[c.withAlpha(0xFF).toARGB32()];
    if (exact != null) return exact.withValues(alpha: c.a);
    final neutral = hsl.saturation < 0.08;
    return hsl
        .withHue(neutral ? _neutralHue : hsl.hue)
        .withSaturation(neutral ? 0.12 : hsl.saturation * 0.5)
        .withLightness(0.90 - 0.4 * hsl.lightness)
        .toColor();
  }

  static Color _darken(
    HSLColor hsl, {
    required double floor,
    required double maxSaturation,
  }) {
    final neutral = hsl.saturation < 0.08;
    return hsl
        .withHue(neutral ? _neutralHue : hsl.hue)
        .withSaturation(
          neutral ? 0.18 : (hsl.saturation * 0.55).clamp(0.0, maxSaturation),
        )
        .withLightness(floor + (1 - hsl.lightness) * 0.45)
        .toColor();
  }
}
