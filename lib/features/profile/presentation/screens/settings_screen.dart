import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/bloc/app_preferences/app_preferences_bloc.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/screens/change_password_screen.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/widgets/delete_account_dialogs.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/widgets/settings_option_row.dart';
import 'package:tuhfatul_muslim/features/legal/domain/entities/legal_document.dart';
import 'package:tuhfatul_muslim/features/legal/presentation/screens/legal_document_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static void _openLegal(BuildContext context, LegalDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalDocumentScreen(type: type)),
    );
  }

  static void _comingSoon(BuildContext context, AppText appText) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appText.comingSoon)));
  }

  static List<SettingsOption> _items(
    BuildContext context,
    AppText appText,
    bool isDark,
    bool isSignedIn,
  ) => [
    SettingsOption(
      appText.aboutUs,
      Icons.person_outline,
      onTap: () => _openLegal(context, LegalDocumentType.aboutUs),
    ),
    SettingsOption(
      appText.ourProducts,
      Icons.eco_outlined,
      onTap: () => _comingSoon(context, appText),
    ),
    SettingsOption(
      appText.privacyPolicy,
      Icons.privacy_tip_outlined,
      onTap: () => _openLegal(context, LegalDocumentType.privacyPolicy),
    ),
    SettingsOption(
      appText.termsOfServices,
      Icons.description_outlined,
      onTap: () => _openLegal(context, LegalDocumentType.termsOfService),
    ),
    SettingsOption(
      appText.adminSupport,
      Icons.support_agent_outlined,
      onTap: () => _comingSoon(context, appText),
    ),
    SettingsOption(
      appText.feedback,
      Icons.feedback_outlined,
      onTap: () => _comingSoon(context, appText),
    ),
    appLanguageOption(context, appText),
    SettingsOption(
      appText.addPrayerWidgetTitle,
      Icons.widgets_outlined,
      onTap: () => Navigator.of(context).pushNamed(RouteNames.addPrayerWidget),
    ),
    themeToggleOption(context, appText, isDark),
    if (isSignedIn)
      SettingsOption(
        appText.changePassword,
        Icons.sync_alt_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isDark = context.watch<AppPreferencesBloc>().state.darkThemeEnabled;
    final isSignedIn = isUserSignedIn;
    final items = _items(context, appText, isDark, isSignedIn);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                children: [
                  for (final item in items) ...[
                    SettingsOptionRow(option: item),
                    SizedBox(height: 12.h),
                  ],
                ],
              ),
            ),
            if (isSignedIn)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: const _DeleteAccountButton(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: appText.back,
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: Color(0xFF303629),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          Text(
            appText.settingsTitle,
            style: TextStyle(
              color: AppColor.primary,
              fontSize: 19.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: OutlinedButton(
        onPressed: () => showDeleteAccountFlow(context),
        style: OutlinedButton.styleFrom(
          backgroundColor: context.surfaceColor(Colors.white),
          foregroundColor: context.inkColor(AppColor.forgotPassword),
          side: const BorderSide(color: AppColor.forgotPassword),
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26.r),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, size: 20),
            SizedBox(width: 10.w),
            Text(
              AppText.of(context).deleteAccount,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
