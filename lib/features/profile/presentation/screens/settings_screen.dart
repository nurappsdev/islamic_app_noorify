import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static List<_SettingsItem> _items(BuildContext context, AppText appText) => [
    _SettingsItem(appText.aboutUs, Icons.person_outline),
    _SettingsItem(appText.ourProducts, Icons.eco_outlined),
    _SettingsItem(appText.privacyPolicy, Icons.privacy_tip_outlined),
    _SettingsItem(appText.termsOfServices, Icons.description_outlined),
    _SettingsItem(appText.adminSupport, Icons.support_agent_outlined),
    _SettingsItem(appText.feedback, Icons.feedback_outlined),
    _SettingsItem(
      appText.appLanguage,
      Icons.translate_outlined,
      onTap: () => Navigator.of(context).pushNamed(RouteNames.appLanguage),
    ),
    _SettingsItem(appText.changePassword, Icons.sync_alt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final items = _items(context, appText);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(onBack: () => Navigator.maybePop(context)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                children: [
                  for (final item in items) ...[
                    _SettingsRow(item: item),
                    SizedBox(height: 12.h),
                  ],
                ],
              ),
            ),
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
                foregroundColor: const Color(0xFF303629),
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

class _SettingsItem {
  const _SettingsItem(this.label, this.icon, {this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: item.onTap ?? () {},
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE8C1)),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: AppColor.primary, size: 19.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  item.label,
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

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColor.forgotPassword,
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
