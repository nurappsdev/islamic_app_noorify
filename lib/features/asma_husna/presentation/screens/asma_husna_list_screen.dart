import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/asma_husna/presentation/bloc/asma_husna_bloc.dart';
import 'package:islami_app_noorify/features/asma_husna/presentation/widgets/asma_name_card.dart';
import 'package:islami_app_noorify/features/asma_husna/presentation/widgets/asma_name_detail_sheet.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_page_header.dart';

/// Full "99 Names" list (design `img_27.png`): a search field over the
/// scrollable list of [AsmaNameCard]s, each streaming its own audio preview.
class AsmaHusnaListScreen extends StatelessWidget {
  const AsmaHusnaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9EC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCFDF7), Color(0xFFEFF2DA)],
          ),
          image: DecorationImage(
            image: AssetImage('assets/asmaulHusna.png'),
            repeat: ImageRepeat.repeat, // Fixed: BoxFit doesn't have 'repeat'
            opacity: 0.15,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: DuaPageHeader(
                  title: appText.asmaHusnaTitle,
                  action: IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColor.authLogo,
                      side: const BorderSide(color: Color(0xFFDCE3BE)),
                      minimumSize: Size(38.r, 38.r),
                    ),
                    icon: const Icon(Icons.access_time, size: 18),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _SearchField(hint: appText.searchHere),
              ),
              SizedBox(height: 18.h),
              Expanded(
                child: BlocBuilder<AsmaHusnaBloc, AsmaHusnaState>(
                  builder: (context, state) {
                    if (state.status == AsmaHusnaStatus.loading ||
                        state.status == AsmaHusnaStatus.initial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == AsmaHusnaStatus.failure) {
                      return _ErrorView(
                        message: state.failure?.message ?? '',
                        onRetry: () => context.read<AsmaHusnaBloc>().add(
                          const LoadAsmaNames(),
                        ),
                        retryLabel: appText.tryAgain,
                      );
                    }
                    final names = state.filteredNames;
                    if (names.isEmpty) {
                      return Center(
                        child: Text(
                          appText.noResultsFound,
                          style: TextStyle(
                            color: AppColor.authHint,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
                      itemCount: names.length,
                      separatorBuilder: (_, _) => SizedBox(height: 20.h),
                      itemBuilder: (context, index) {
                        final name = names[index];
                        final audioUrl = name.audioUrl;
                        return AsmaNameCard(
                          name: name,
                          isPlaying:
                              state.playingId == name.id && !state.isBuffering,
                          isBuffering:
                              state.playingId == name.id && state.isBuffering,
                          onTogglePlay: audioUrl == null || audioUrl.isEmpty
                              ? null
                              : () => context.read<AsmaHusnaBloc>().add(
                                  TogglePlayAsmaAudio(
                                    nameId: name.id,
                                    audioUrl: audioUrl,
                                  ),
                                ),
                          onShowDetails: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AsmaNameDetailSheet(name: name),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextStyle(fontSize: 13.sp),
      onChanged: (value) =>
          context.read<AsmaHusnaBloc>().add(SearchAsmaNames(value)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
        prefixIcon: Icon(Icons.search, color: AppColor.authIcon, size: 20.sp),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 14.h),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: Color(0xFFE3E7D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: AppColor.primary),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColor.authHint, size: 36.sp),
            SizedBox(height: 10.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
            ),
            SizedBox(height: 14.h),
            OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
