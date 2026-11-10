import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/bloc/app_preferences/app_preferences_bloc.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// One row of the Settings list: a label, its icon and what tapping it does.
class SettingsOption {
  const SettingsOption(this.label, this.icon, {this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

/// The App Language row. Shared by the Settings and Profile screens so the
/// same option looks and behaves identically wherever it is shown.
SettingsOption appLanguageOption(BuildContext context, AppText appText) =>
    SettingsOption(
      appText.appLanguage,
      Icons.translate_outlined,
      onTap: () => Navigator.of(context).pushNamed(RouteNames.appLanguage),
    );

/// The dark/light theme row, labelled with the theme it switches *to*.
/// Shared by the Settings and Profile screens: both flip the one
/// [AppPreferencesBloc], which saves the choice, so the two stay in step.
SettingsOption themeToggleOption(
  BuildContext context,
  AppText appText,
  bool isDark,
) => SettingsOption(
  isDark ? appText.themeSwitchToLight : appText.themeSwitchToDark,
  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
  onTap: () => context.read<AppPreferencesBloc>().add(const ToggleDarkTheme()),
);

class SettingsOptionRow extends StatelessWidget {
  const SettingsOptionRow({super.key, required this.option});

  final SettingsOption option;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaceColor(Colors.white),
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: option.onTap ?? () {},
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: AppColor.primary, size: 19.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(color: AppColor.primary, fontSize: 14.sp),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColor.primary,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
