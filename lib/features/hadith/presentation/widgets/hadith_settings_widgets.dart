import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// The pieces the Hadith settings screens are built from, after the
/// "Three dot settings" design (`devImg/img_20.png`): a close button over a
/// title, section headers with a small accent bar, and cards of rows that
/// each carry an icon badge, a title and subtitle, and a control.

/// Close button on the left with the screen's name beside it.
class HadithSettingsHeader extends StatelessWidget {
  const HadithSettingsHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
      child: Row(
        children: [
          IconButton(
            tooltip: AppText.of(context).back,
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              // A pale badge in both themes, so its icon stays dark.
              backgroundColor: const Color(0xFFCBD16B),
              foregroundColor: context.onLightInkColor(const Color(0xFF303629)),
              minimumSize: Size(38.r, 38.r),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: context.textInkColor(const Color(0xFF2C3320)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase section label with the design's small accent bar.
class HadithSettingsSection extends StatelessWidget {
  const HadithSettingsSection({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: context.surfaceColor(const Color(0xFFD08A3E)),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: context.textInkColor(const Color(0xFF8B9A4B)),
            ),
          ),
        ),
      ],
    );
  }
}

/// The card a section's rows sit in, with a divider between them.
class HadithSettingsCard extends StatelessWidget {
  const HadithSettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.lineColor(const Color(0xFFE3E7D3))),
      ),
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                color: context.lineColor(const Color(0xFFEDEFE0)),
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// One row: an icon badge, a title and subtitle, and either a [trailing]
/// control or — when the row is a choice — a check that marks [selected].
class HadithSettingsRow extends StatelessWidget {
  const HadithSettingsRow({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.surfaceColor(iconBg),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 17.sp, color: context.inkColor(iconColor)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textInkColor(const Color(0xFF2C3320)),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    height: 1.4,
                    color: context.textInkColor(const Color(0xFF7C8A63)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          trailing ?? HadithSettingsCheck(selected: selected),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: row,
    );
  }
}

/// The circular check that marks a chosen row.
class HadithSettingsCheck extends StatelessWidget {
  const HadithSettingsCheck({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.r,
      height: 24.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? context.surfaceColor(const Color(0xFFEDEFD8))
            : Colors.transparent,
        border: Border.all(
          color: context.lineColor(
            selected ? AppColor.primary : const Color(0xFFDDE8C1),
          ),
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 13.sp, color: AppColor.primary)
          : null,
    );
  }
}

/// A row that opens another screen: its current [value] and a chevron in
/// place of a control.
class HadithSettingsLink extends StatelessWidget {
  const HadithSettingsLink({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HadithSettingsRow(
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Padding(
        padding: EdgeInsets.only(top: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: context.textInkColor(const Color(0xFF9BA85B)),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: context.inkColor(const Color(0xFF9BA85B)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled font-size slider with the design's value pill beside it.
class HadithSettingsSizeSlider extends StatelessWidget {
  const HadithSettingsSizeSlider({
    super.key,
    required this.icon,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final IconData icon;
  final String label;

  /// The size as the design shows it, e.g. "120%".
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;

  /// Null leaves the slider disabled, for a text that is switched off.
  final ValueChanged<double>? onChanged;

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
                  color: context.textInkColor(const Color(0xFF2C3320)),
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
                valueLabel,
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
            inactiveTrackColor: context.surfaceColor(const Color(0xFFEBDCA8)),
            thumbColor: _accent,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
