import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';
import 'brand_colors.dart';

/// The app's light theme (the look the app has always had).
ThemeData lightTheme({String fontFamily = appFontFamily}) => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color.fromRGBO(30, 168, 184, 1),
  scaffoldBackgroundColor: BrandColors.screenBackground,
  fontFamily: fontFamily,
  textTheme: ThemeData().textTheme.apply(fontFamily: fontFamily),
  extensions: const [AppPalette.light],
);
