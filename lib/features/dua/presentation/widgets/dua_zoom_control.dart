import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_settings/dua_settings_bloc.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// "Typography & Script Styling" sliders in the reader's settings sheet
/// (design `devImg/img_20.png`): separate Arabic and translation font
/// sizes, each shown with its current size in px.
class DuaFontSizeControls extends StatelessWidget {
  const DuaFontSizeControls({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<DuaSettingsBloc>().state;
    return Column(
      children: [
        _FontSizeRow(
          icon: Icons.menu_book_rounded,
          label: appText.duaArabicFontSizeLabel,
          value: state.arabicFontSize,
          // 16-50px: the 20px default scaled down to 80% and up to 250%,
          // the same reach the Quran and Hadith readers allow.
          min: 16,
          max: 50,
          onChanged: (value) =>
              context.read<DuaSettingsBloc>().add(SetDuaArabicFontSize(value)),
        ),
        SizedBox(height: 16.h),
        _FontSizeRow(
          icon: Icons.translate_rounded,
          label: appText.duaTranslationFontSizeLabel,
          value: state.translationFontSize,
          // 10-30px, around the 12px default.
          min: 10,
          max: 30,
          onChanged: (value) => context.read<DuaSettingsBloc>().add(
            SetDuaTranslationFontSize(value),
          ),
        ),
      ],
    );
  }
}

class _FontSizeRow extends StatelessWidget {
  const _FontSizeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  static const _accent = Color(0xFFD08A3E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15.sp, color: context.inkColor(_accent)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(const Color(0xFF2C3320)),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: context.surfaceColor(const Color(0xFFFBF0DD)),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                context.localizedDigits('${value.round()}px'),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: context.inkColor(_accent),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
            activeTrackColor: _accent,
            inactiveTrackColor: const Color(0xFFEBDCA8),
            thumbColor: _accent,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
