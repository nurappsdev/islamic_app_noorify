import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_content_settings.dart';

/// Right-hand drawer with the hadith list's content settings: show Arabic,
/// show translation, and the Arabic / translation font sizes.
class HadithContentSettingsDrawer extends StatelessWidget {
  const HadithContentSettingsDrawer({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final HadithContentSettings settings;
  final ValueChanged<HadithContentSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText.quranReaderSettingsTitle,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3320),
                ),
              ),
              SizedBox(height: 10.h),
              // At least one text stays on, so a card is never empty.
              _ToggleRow(
                label: appText.showArabicLabel,
                value: settings.showArabic,
                onChanged: settings.showArabic && !settings.showTranslation
                    ? null
                    : (v) => onChanged(settings.copyWith(showArabic: v)),
              ),
              _ToggleRow(
                label: appText.showTranslationLabel,
                value: settings.showTranslation,
                onChanged: settings.showTranslation && !settings.showArabic
                    ? null
                    : (v) => onChanged(settings.copyWith(showTranslation: v)),
              ),
              const Divider(height: 28, color: Color(0xFFE3E7D3)),
              _SizeSlider(
                label: appText.quranArabicSizeLabel,
                value: settings.arabicScale,
                enabled: settings.showArabic,
                onChanged: (v) => onChanged(settings.copyWith(arabicScale: v)),
              ),
              SizedBox(height: 8.h),
              _SizeSlider(
                label: appText.quranTranslationSizeLabel,
                value: settings.translationScale,
                enabled: settings.showTranslation,
                onChanged: (v) =>
                    onChanged(settings.copyWith(translationScale: v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeThumbColor: AppColor.primary,
      title: Text(label, style: TextStyle(fontSize: 13.5.sp)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SizeSlider extends StatelessWidget {
  const _SizeSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A6350),
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9BA85B)),
            ),
          ],
        ),
        Slider(
          value: value.clamp(
            HadithContentSettings.minScale,
            HadithContentSettings.maxScale,
          ),
          min: HadithContentSettings.minScale,
          max: HadithContentSettings.maxScale,
          divisions: 8,
          activeColor: AppColor.primary,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
