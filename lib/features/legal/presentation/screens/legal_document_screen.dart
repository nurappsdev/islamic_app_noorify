import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/legal/data/datasources/legal_remote_data_source.dart';
import 'package:islami_app_noorify/features/legal/data/repositories/legal_repository_impl.dart';
import 'package:islami_app_noorify/features/legal/domain/entities/legal_document.dart';
import 'package:islami_app_noorify/features/legal/domain/usecases/get_legal_document.dart';
import 'package:islami_app_noorify/features/legal/presentation/cubit/legal_document_cubit.dart';

/// Shows the Terms of Service or Privacy Policy, loaded from the API and
/// rendered as HTML.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  String get _fallbackTitle => switch (type) {
    LegalDocumentType.aboutUs => 'About Us',
    LegalDocumentType.termsOfService => 'Terms of Service',
    LegalDocumentType.privacyPolicy => 'Privacy Policy',
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LegalDocumentCubit(
        GetLegalDocument(LegalRepositoryImpl(LegalRemoteDataSourceImpl())),
        type,
      )..load(),
      child: BlocBuilder<LegalDocumentCubit, LegalDocumentState>(
        builder: (context, state) {
          final ink = context.inkColor(AppColor.authLogo);
          final title = state.document?.title.isNotEmpty == true
              ? state.document!.title
              : _fallbackTitle;
          return Scaffold(
            backgroundColor: context.pageColor(Colors.white),
            body: SafeArea(
              child: Column(
                children: [
                  _LegalHeader(title: title),
                  Expanded(child: _body(context, state, ink)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, LegalDocumentState state, Color ink) {
    switch (state.status) {
      case LegalDocumentStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColor.primary),
        );
      case LegalDocumentStatus.failure:
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ink, fontSize: 14.sp),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => context.read<LegalDocumentCubit>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case LegalDocumentStatus.success:
        final document = state.document!;
        final dates = [
          if (document.effectiveDate != null)
            'Effective: ${document.effectiveDate}',
          if (document.lastUpdated != null)
            'Last updated: ${document.lastUpdated}',
        ].join('  •  ');
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: context.lineColor(const Color(0xFFDDE8C1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dates.isNotEmpty) ...[
                  Text(
                    dates,
                    style: TextStyle(
                      color: ink.withValues(alpha: .6),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
                HtmlWidget(
                  document.content,
                  textStyle: TextStyle(
                    color: ink,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

/// Same header as the settings screen: lime back button, centered title.
class _LegalHeader extends StatelessWidget {
  const _LegalHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDFDE68),
                  foregroundColor: const Color(0xFF303629),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 56.w),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColor.primary,
                fontSize: 19.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
