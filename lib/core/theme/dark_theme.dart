import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_color.dart';
import 'app_palette.dart';
import 'brand_colors.dart';

/// The app's dark theme: the olive brand on deep green-black surfaces.
ThemeData darkTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: BrandColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        surface: AppColor.darkSurface,
        onSurface: AppColor.darkTextPrimary,
        outlineVariant: AppColor.darkBorder,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColor.darkBackground,
    canvasColor: AppColor.darkBackground,
    cardColor: AppColor.darkSurface,
    dividerColor: AppColor.darkBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.darkBackground,
      foregroundColor: AppColor.darkTextPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    extensions: const [AppPalette.dark],
  );
}
