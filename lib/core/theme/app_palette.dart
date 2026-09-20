import 'package:flutter/material.dart';

import '../utils/app_color.dart';

/// App-specific colors that a [ColorScheme] has no slot for (the olive tints,
/// card borders, danger surfaces...). One instance per theme, read with
/// `context.appPalette`. The raw values live in [AppColor].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.tint,
    required this.tintSoft,
    required this.avatar,
    required this.textPrimary,
    required this.textStrong,
    required this.progressTrack,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.dangerSurface,
    required this.dangerTint,
  });

  static const light = AppPalette(
    background: AppColor.lightBackground,
    surface: AppColor.lightSurface,
    border: AppColor.lightBorder,
    tint: AppColor.lightTint,
    tintSoft: AppColor.lightTintSoft,
    avatar: AppColor.lightAvatar,
    textPrimary: AppColor.lightTextPrimary,
    textStrong: AppColor.lightTextStrong,
    progressTrack: AppColor.lightProgressTrack,
    shimmerBase: AppColor.lightShimmerBase,
    shimmerHighlight: AppColor.lightShimmerHighlight,
    dangerSurface: AppColor.lightDangerSurface,
    dangerTint: AppColor.lightDangerTint,
  );

  static const dark = AppPalette(
    background: AppColor.darkBackground,
    surface: AppColor.darkSurface,
    border: AppColor.darkBorder,
    tint: AppColor.darkTint,
    tintSoft: AppColor.darkTintSoft,
    avatar: AppColor.darkAvatar,
    textPrimary: AppColor.darkTextPrimary,
    textStrong: AppColor.darkTextStrong,
    progressTrack: AppColor.darkProgressTrack,
    shimmerBase: AppColor.darkShimmerBase,
    shimmerHighlight: AppColor.darkShimmerHighlight,
    dangerSurface: AppColor.darkDangerSurface,
    dangerTint: AppColor.darkDangerTint,
  );

  /// Screen background.
  final Color background;

  /// Cards and other raised surfaces.
  final Color surface;
  final Color border;

  /// Olive fill behind small buttons and highlighted cards.
  final Color tint;
  final Color tintSoft;
  final Color avatar;
  final Color textPrimary;

  /// Slightly stronger text used for serif headings.
  final Color textStrong;
  final Color progressTrack;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color dangerSurface;
  final Color dangerTint;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? tint,
    Color? tintSoft,
    Color? avatar,
    Color? textPrimary,
    Color? textStrong,
    Color? progressTrack,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? dangerSurface,
    Color? dangerTint,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      tint: tint ?? this.tint,
      tintSoft: tintSoft ?? this.tintSoft,
      avatar: avatar ?? this.avatar,
      textPrimary: textPrimary ?? this.textPrimary,
      textStrong: textStrong ?? this.textStrong,
      progressTrack: progressTrack ?? this.progressTrack,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      dangerTint: dangerTint ?? this.dangerTint,
    );
  }

  /// Blends every color so switching themes fades instead of snapping.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      border: mix(border, other.border),
      tint: mix(tint, other.tint),
      tintSoft: mix(tintSoft, other.tintSoft),
      avatar: mix(avatar, other.avatar),
      textPrimary: mix(textPrimary, other.textPrimary),
      textStrong: mix(textStrong, other.textStrong),
      progressTrack: mix(progressTrack, other.progressTrack),
      shimmerBase: mix(shimmerBase, other.shimmerBase),
      shimmerHighlight: mix(shimmerHighlight, other.shimmerHighlight),
      dangerSurface: mix(dangerSurface, other.dangerSurface),
      dangerTint: mix(dangerTint, other.dangerTint),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The active theme's [AppPalette] (light when none is registered).
  AppPalette get appPalette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
