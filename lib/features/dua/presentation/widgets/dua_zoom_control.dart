import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/dua/presentation/bloc/dua_settings/dua_settings_bloc.dart';

class DuaZoomControl extends StatelessWidget {
  const DuaZoomControl({super.key});

  @override
  Widget build(BuildContext context) {
    final multiplier = context.select<DuaSettingsBloc, double>(
      (bloc) => bloc.state.fontSizeMultiplier,
    );
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
              value: multiplier,
              min: 0.8,
              max: 2.5,
              onChanged: (val) {
                context.read<DuaSettingsBloc>().add(SetDuaFontSize(val));
              },
            ),
          ),
        ),
        Text(
          '${(multiplier * 100).toInt()}%',
          style: TextStyle(
            fontSize: 11.sp,
            color: context.inkColor(Color(0xFF6B7458)),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
