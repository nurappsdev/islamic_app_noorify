import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_content_settings.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/widgets/hadith_settings_widgets.dart';

/// Reading-language setup for the Hadith section (design `devImg/img_20.png`:
/// a close button over sectioned cards of icon-badge rows).
///
/// Sets which texts a hadith is read in — the Arabic original, and the
/// translation beside it — and nothing else: the app's own language stays
/// where the reader left it, on Settings > App Language.
///
/// [settings] is the state the screen opens with; every change is reported
/// through [onChanged] as it is made, so the screen that owns the settings
/// (and its store) stays the single source of truth.
class HadithLanguageScreen extends StatefulWidget {
  const HadithLanguageScreen({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final HadithContentSettings settings;
  final ValueChanged<HadithContentSettings> onChanged;

  @override
  State<HadithLanguageScreen> createState() => _HadithLanguageScreenState();
}

class _HadithLanguageScreenState extends State<HadithLanguageScreen> {
  late HadithContentSettings _settings = widget.settings;

  void _update(HadithContentSettings value) {
    setState(() => _settings = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final language = _settings.translationLanguage;
    return Scaffold(
      backgroundColor: context.pageColor(const Color(0xFFFCFDF8)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HadithSettingsHeader(title: appText.hadithLanguageTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 28.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HadithSettingsSection(title: appText.hadithLanguageSection),
                    SizedBox(height: 10.h),
                    HadithSettingsCard(
                      children: [
                        HadithSettingsRow(
                          icon: Icons.menu_book_rounded,
                          iconBg: const Color(0xFFF3DCC4),
                          iconColor: const Color(0xFFB07A2E),
                          title: appText.showArabicLabel,
                          subtitle: appText.hadithLanguageArabicSubtitle,
                          // The card would be empty with both texts off, so
                          // the last one standing cannot be switched off —
                          // the same rule the settings drawer applies.
                          trailing: Switch(
                            value: _settings.showArabic,
                            activeThumbColor: AppColor.primary,
                            onChanged:
                                _settings.showArabic &&
                                    !_settings.showTranslation
                                ? null
                                : (value) => _update(
                                    _settings.copyWith(showArabic: value),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    HadithSettingsSection(
                      title: appText.hadithLanguageTranslationSection,
                    ),
                    SizedBox(height: 10.h),
                    HadithSettingsCard(
                      children: [
                        HadithSettingsRow(
                          icon: Icons.translate_rounded,
                          iconBg: const Color(0xFFDCEEC0),
                          iconColor: const Color(0xFF2F6B3C),
                          title: appText.bangla,
                          subtitle: appText.hadithLanguageBanglaSubtitle,
                          selected:
                              language == HadithTranslationLanguage.bangla,
                          onTap: () => _update(
                            _settings.copyWith(
                              translationLanguage:
                                  HadithTranslationLanguage.bangla,
                            ),
                          ),
                        ),
                        HadithSettingsRow(
                          icon: Icons.language_rounded,
                          iconBg: const Color(0xFFE3DAF5),
                          iconColor: const Color(0xFF7C5FC4),
                          title: appText.english,
                          subtitle: appText.hadithLanguageEnglishSubtitle,
                          selected:
                              language == HadithTranslationLanguage.english,
                          onTap: () => _update(
                            _settings.copyWith(
                              translationLanguage:
                                  HadithTranslationLanguage.english,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14.sp,
                          color: context.inkColor(const Color(0xFF9BA85B)),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            appText.hadithLanguageNote,
                            style: TextStyle(
                              fontSize: 11.sp,
                              height: 1.4,
                              color: context.textInkColor(
                                const Color(0xFF9BA85B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
