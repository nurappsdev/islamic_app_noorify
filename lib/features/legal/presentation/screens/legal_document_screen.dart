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
          return Scaffold(
            backgroundColor: context.pageColor(AppColor.authBackground),
            appBar: AppBar(
              backgroundColor: context.pageColor(AppColor.authBackground),
              elevation: 0,
              foregroundColor: ink,
              title: Text(
                state.document?.title.isNotEmpty == true
                    ? state.document!.title
                    : _fallbackTitle,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
              ),
            ),
            body: SafeArea(child: _body(context, state, ink)),
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
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 24.h),
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
                textStyle: TextStyle(color: ink, fontSize: 14.sp, height: 1.5),
              ),
            ],
          ),
        );
    }
  }
}
