import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/bloc/app_preferences/app_preferences_bloc.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/all_alarm_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';
import 'package:islami_app_noorify/shared/widgets/profile_avatar_circle.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final palette = context.appPalette;
    final isDark = context.watch<AppPreferencesBloc>().state.darkThemeEnabled;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
          child: ProfileAvatarCircle(
            dimension: 38.r,
            backgroundColor: context.surfaceColor(palette.avatar),
            placeholderIconColor: AppColor.primary,
          ),
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: profileNameNotifier,
                  builder: (context, name, _) {
                    return Text(
                      (name == null || name.isEmpty)
                          ? appText.competitorName
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: homeSansStyle(
                        context: context,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                SizedBox(height: 2.h),
                Text(
                  appText.greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: homeSansStyle(context: context, fontSize: 8.sp),
                ),
              ],
            ),
          ),
        ),
        SizedBox.square(
          dimension: 32.r,
          child: IconButton(
            tooltip: isDark
                ? appText.themeSwitchToLight
                : appText.themeSwitchToDark,
            onPressed: () =>
                context.read<AppPreferencesBloc>().add(const ToggleDarkTheme()),
            padding: EdgeInsets.zero,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColor.primary,
              size: 20.sp,
            ),
          ),
        ),
        SizedBox.square(
          dimension: 32.r,
          child: IconButton(
            tooltip: appText.alarm,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AllAlarmScreen()),
            ),
            padding: EdgeInsets.zero,
            icon: Icon(Icons.alarm, color: AppColor.primary, size: 20.sp),
          ),
        ),
        // Notification bell hidden until notifications are wired up.
        // Stack(
        //   clipBehavior: Clip.none,
        //   children: [
        //     SizedBox.square(
        //       dimension: 36.r,
        //       child: IconButton(
        //         tooltip: appText.notifications,
        //         onPressed: () {},
        //         padding: EdgeInsets.zero,
        //         style: IconButton.styleFrom(
        //           backgroundColor: context.surfaceColor(palette.tint),
        //           foregroundColor: AppColor.primary,
        //         ),
        //         icon: Icon(Icons.notifications_none, size: 20.sp),
        //       ),
        //     ),
        //     Positioned(
        //       top: 6.h,
        //       right: 8.w,
        //       child: Container(
        //         width: 9.r,
        //         height: 9.r,
        //         decoration: BoxDecoration(
        //           color: const Color(0xFFFF6969),
        //           shape: BoxShape.circle,
        //           border: Border.all(
        //             color: context.lineColor(palette.background),
        //             width: 1.2,
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
