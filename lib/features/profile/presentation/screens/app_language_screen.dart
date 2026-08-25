import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class AppLanguageScreen extends StatelessWidget {
  const AppLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final selected = context.watch<LanguageBloc>().state.language;
    final bloc = context.read<LanguageBloc>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _LanguageHeader(onBack: () => Navigator.maybePop(context)),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Column(
                children: [
                  _LanguageOption(
                    title: appText.bangla,
                    subtitle: appText.defaultLabel,
                    selected: selected == AppLanguage.bangla,
                    onTap: () =>
                        bloc.add(const UpdateLanguage(AppLanguage.bangla)),
                  ),
                  SizedBox(height: 12.h),
                  _LanguageOption(
                    title: appText.english,
                    selected: selected == AppLanguage.english,
                    onTap: () =>
                        bloc.add(const UpdateLanguage(AppLanguage.english)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader({required this.onBack});

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
            appText.languageTitle,
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

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF3F5E4) : Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE8C1)),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColor.primary,
                        fontSize: 14.sp,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: AppColor.primary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 26.r,
                height: 26.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFFEDEFD8)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColor.primary
                        : const Color(0xFFDDE8C1),
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 14.sp, color: AppColor.primary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
