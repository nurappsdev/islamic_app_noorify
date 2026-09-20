import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'brand_colors.dart';

/// The app's light theme (the look the app has always had).
ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color.fromRGBO(30, 168, 184, 1),
  scaffoldBackgroundColor: BrandColors.screenBackground,
  textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  extensions: const [AppPalette.light],
);
