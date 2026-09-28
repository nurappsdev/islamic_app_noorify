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
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/core/localization/localization_context.dart';

/// Shows the Terms of Service or Privacy Policy, loaded from the API and
/// rendered as HTML.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  String _fallbackTitle(AppText appText) => switch (type) {
    LegalDocumentType.aboutUs => appText.aboutUs,
    LegalDocumentType.termsOfService => appText.termsOfServices,
    LegalDocumentType.privacyPolicy => appText.privacyPolicy,
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
              : _fallbackTitle(AppText.of(context));
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
                  state.errorMessage ?? AppText.of(context).failureUnknown,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ink, fontSize: 14.sp),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => context.read<LegalDocumentCubit>().load(),
                  child: Text(AppText.of(context).tryAgain),
                ),
              ],
            ),
          ),
        );
      case LegalDocumentStatus.success:
        final document = state.document!;
        final appText = AppText.of(context);
        // The API sends the dates as text (`2026-01-01`); written out in the
        // selected language when it is a date, with localized digits if not.
        String dateText(String raw) {
          final date = DateTime.tryParse(raw);
          return date == null
              ? context.localizedDigits(raw)
              : context.localizedDates.gregorian(date);
        }

        final dates = [
          if (document.effectiveDate != null)
            appText.legalEffectiveLabel.replaceAll(
              '{date}',
              dateText(document.effectiveDate!),
            ),
          if (document.lastUpdated != null)
            appText.legalLastUpdatedLabel.replaceAll(
              '{date}',
              dateText(document.lastUpdated!),
            ),
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
