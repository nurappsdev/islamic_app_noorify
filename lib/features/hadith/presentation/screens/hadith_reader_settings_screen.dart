import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_content_settings.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/screens/hadith_language_screen.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/widgets/hadith_settings_widgets.dart';

/// Everything the "Tt" button in the hadith reader opens: which texts show,
/// the language they are read in, and how large they are — as the
/// "Three dot settings" design lays it out (`devImg/img_20.png`).
///
/// It replaced the side drawer the button used to open. [settings] is the
/// state it opens with, and every change is reported through [onChanged] as
/// it is made, so the reader that owns the settings (and its store) stays
/// the single source of truth.
class HadithReaderSettingsScreen extends StatefulWidget {
  const HadithReaderSettingsScreen({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final HadithContentSettings settings;
  final ValueChanged<HadithContentSettings> onChanged;

  @override
  State<HadithReaderSettingsScreen> createState() =>
      _HadithReaderSettingsScreenState();
}

class _HadithReaderSettingsScreenState
    extends State<HadithReaderSettingsScreen> {
  late HadithContentSettings _settings = widget.settings;

  void _update(HadithContentSettings value) {
    setState(() => _settings = value);
    widget.onChanged(value);
  }

  /// The slider moves in 10% steps across whatever range the settings
  /// allow, so widening that range adds steps instead of stretching them.
  static int get _scaleDivisions =>
      ((HadithContentSettings.maxScale - HadithContentSettings.minScale) * 10)
          .round();

  String _percent(BuildContext context, double scale) =>
      context.localizedDigits('${(scale * 100).round()}%');

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(const Color(0xFFFCFDF8)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HadithSettingsHeader(title: appText.quranReaderSettingsTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 28.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HadithSettingsSection(
                      title: appText.duaDisplayReadingStyleSection,
                    ),
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
                          // the last one standing cannot be switched off.
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
                        HadithSettingsRow(
                          icon: Icons.translate_rounded,
                          iconBg: const Color(0xFFFBDFE6),
                          iconColor: const Color(0xFFB0527A),
                          title: appText.showTranslationLabel,
                          subtitle: appText.hadithLanguageBanglaSubtitle,
                          trailing: Switch(
                            value: _settings.showTranslation,
                            activeThumbColor: AppColor.primary,
                            onChanged:
                                _settings.showTranslation &&
                                    !_settings.showArabic
                                ? null
                                : (value) => _update(
                                    _settings.copyWith(showTranslation: value),
                                  ),
                          ),
                        ),
                        HadithSettingsLink(
                          icon: Icons.language_rounded,
                          iconBg: const Color(0xFFDCEEC0),
                          iconColor: const Color(0xFF2F6B3C),
                          title: appText.hadithLanguageTitle,
                          subtitle: appText.hadithLanguageSection,
                          value:
                              _settings.translationLanguage ==
                                  HadithTranslationLanguage.english
                              ? appText.english
                              : appText.bangla,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => HadithLanguageScreen(
                                settings: _settings,
                                onChanged: _update,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    HadithSettingsSection(
                      title: appText.duaTypographyStylingSection,
                    ),
                    SizedBox(height: 10.h),
                    HadithSettingsCard(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: HadithSettingsSizeSlider(
                            icon: Icons.menu_book_rounded,
                            label: appText.quranArabicSizeLabel,
                            valueLabel: _percent(
                              context,
                              _settings.arabicScale,
                            ),
                            value: _settings.arabicScale,
                            min: HadithContentSettings.minScale,
                            max: HadithContentSettings.maxScale,
                            divisions: _scaleDivisions,
                            onChanged: _settings.showArabic
                                ? (value) => _update(
                                    _settings.copyWith(arabicScale: value),
                                  )
                                : null,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: HadithSettingsSizeSlider(
                            icon: Icons.translate_rounded,
                            label: appText.quranTranslationSizeLabel,
                            valueLabel: _percent(
                              context,
                              _settings.translationScale,
                            ),
                            value: _settings.translationScale,
                            min: HadithContentSettings.minScale,
                            max: HadithContentSettings.maxScale,
                            divisions: _scaleDivisions,
                            onChanged: _settings.showTranslation
                                ? (value) => _update(
                                    _settings.copyWith(translationScale: value),
                                  )
                                : null,
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
