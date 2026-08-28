import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_translation/quran_translation_bloc.dart';

/// Which text a [QuranZoomControl] resizes.
enum QuranZoomTarget { arabic, translation }

class QuranZoomControl extends StatelessWidget {
  const QuranZoomControl({super.key, this.target = QuranZoomTarget.arabic});

  final QuranZoomTarget target;

  double _value(QuranTranslationBloc bloc) => target == QuranZoomTarget.arabic
      ? bloc.state.arabicFontScale
      : bloc.state.translationFontScale;

  void _set(BuildContext context, double val) {
    final event = target == QuranZoomTarget.arabic
        ? SetArabicFontScale(val)
        : SetTranslationFontScale(val);
    context.read<QuranTranslationBloc>().add(event);
  }

  @override
  Widget build(BuildContext context) {
    final value = context.select<QuranTranslationBloc, double>(_value);
    return Row(
      children: [
        Icon(Icons.format_size_rounded, size: 16.sp, color: AppColor.primary),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.h,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
              activeTrackColor: AppColor.primary,
              inactiveTrackColor: const Color(0xFFD8E2B0),
              thumbColor: AppColor.primary,
            ),
            child: Slider(
              value: value,
              min: 0.8,
              max: 2.5,
              onChanged: (val) => _set(context, val),
            ),
          ),
        ),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF6B7458),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
