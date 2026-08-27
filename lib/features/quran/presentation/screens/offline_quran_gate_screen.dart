import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/offline_quran/offline_quran_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/surah_list_screen.dart';

/// Entry point for the "Offline Quran" button.
///
/// On first use it asks the user to set up the offline Quran (a one-time,
/// on-device build from the bundled Quran file); once that has finished — now
/// or on a previous visit — it shows the offline surah list, which reads
/// entirely from the local database.
class OfflineQuranGateScreen extends StatelessWidget {
  const OfflineQuranGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineQuranBloc, OfflineQuranState>(
      builder: (context, state) {
        switch (state.status) {
          case OfflineQuranStatus.ready:
            return const SurahListScreen(offline: true);
          case OfflineQuranStatus.checking:
            return const _GateScaffold(
              child: Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              ),
            );
          case OfflineQuranStatus.needsSetup:
          case OfflineQuranStatus.preparing:
          case OfflineQuranStatus.failed:
            return _GateScaffold(child: _SetupPrompt(state: state));
        }
      },
    );
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColor.authLogo,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: child,
        ),
      ),
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  const _SetupPrompt({required this.state});

  final OfflineQuranState state;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isPreparing = state.status == OfflineQuranStatus.preparing;
    final hasFailed = state.status == OfflineQuranStatus.failed;
    final percent = state.progress == null
        ? null
        : (state.progress! * 100).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96.w,
          height: 96.w,
          decoration: const BoxDecoration(
            color: Color(0xFFE7EECB),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPreparing ? Icons.hourglass_bottom_rounded : Icons.menu_book_rounded,
            size: 44.sp,
            color: AppColor.primary,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          appText.offlineQuranTitle,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColor.primary,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          isPreparing
              ? appText.offlineQuranPreparing
              : appText.offlineQuranDownloadIntro,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            height: 1.5,
            color: const Color(0xFF5A6350),
          ),
        ),
        SizedBox(height: 28.h),
        if (isPreparing) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8.h,
              backgroundColor: const Color(0xFFE0E6CC),
              color: AppColor.primary,
            ),
          ),
          if (percent != null) ...[
            SizedBox(height: 10.h),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF7A8368),
              ),
            ),
          ],
        ] else ...[
          if (hasFailed) ...[
            Text(
              appText.offlineQuranSetupFailed,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.red.shade400),
            ),
            if ((state.errorMessage ?? '').isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF9AA187),
                ),
              ),
            ],
            SizedBox(height: 16.h),
          ],
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton(
              onPressed: () => context.read<OfflineQuranBloc>().add(
                const PrepareOfflineQuran(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(
                hasFailed
                    ? appText.offlineQuranResume
                    : appText.offlineQuranDownloadAction,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              appText.offlineQuranNotNow,
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF7A8368)),
            ),
          ),
        ],
      ],
    );
  }
}
