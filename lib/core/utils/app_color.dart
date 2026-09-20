import 'package:flutter/material.dart';

abstract final class AppColor {
  static const Color whiteColor = Color(0xffFFFFFF);
  static const primary = Color(0xFFA1AD59);
  static const authBackground = Colors.white;
  static const authFieldBorder = Color(0xFFDDE8C1);
  static const authHint = Color(0xFFB8B8B8);
  static const authIcon = Color(0xFFB8B8B8);
  static const authLogo = Color(0xFF7D8765);
  static const otpFieldFill = Color(0xFFDDE8AE);
  static const otpDigit = Color(0xFF7D8765);
  static const forgotPassword = Color(0xFFD1212C);
  static const createAccount = Color(0xFF20C463);

  // Light palette (the values the screens have always used).
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE4E8C8);
  static const lightTint = Color(0xFFDDE8AE);
  static const lightTintSoft = Color(0xFFF7F8E8);
  static const lightAvatar = Color(0xFFE8EBC9);
  static const lightTextPrimary = Color(0xFF233021);
  static const lightTextStrong = Color(0xFF1F2B1C);
  static const lightProgressTrack = Color(0xFFE0E0E0);
  static const lightShimmerBase = Color(0xFFE3ECC5);
  static const lightShimmerHighlight = Color(0xFFF6F9EC);
  static const lightDangerSurface = Color(0xFFFFF4F4);
  static const lightDangerTint = Color(0xFFFFD8D8);

  // Dark palette: the same olive brand, on deep green-black surfaces.
  static const darkBackground = Color(0xFF12150E);
  static const darkSurface = Color(0xFF1B2015);
  static const darkBorder = Color(0xFF2F3625);
  static const darkTint = Color(0xFF343D24);
  static const darkTintSoft = Color(0xFF262D1C);
  static const darkAvatar = Color(0xFF2C3320);
  static const darkTextPrimary = Color(0xFFE7EBD8);
  static const darkTextStrong = Color(0xFFF1F4E6);
  static const darkProgressTrack = Color(0xFF3A4130);
  static const darkShimmerBase = Color(0xFF232A1A);
  static const darkShimmerHighlight = Color(0xFF323B25);
  static const darkDangerSurface = Color(0xFF2E1A1A);
  static const darkDangerTint = Color(0xFF4A2626);
}
