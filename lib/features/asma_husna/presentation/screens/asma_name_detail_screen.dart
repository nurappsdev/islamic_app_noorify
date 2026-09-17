import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name_detail.dart';
import 'package:islami_app_noorify/features/asma_husna/presentation/bloc/asma_name_detail_bloc.dart';

/// Full-screen explanation for one name (design `img_29.png`), opened from
/// its card's "Click to see details" button. Fetches
/// `GET /asma-ul-husna/{id}` for the long-form explanation; [name] (already
/// held by the list) only supplies the order badge shown top-left.
class AsmaNameDetailScreen extends StatefulWidget {
  const AsmaNameDetailScreen({super.key, required this.name});

  final AsmaName name;

  @override
  State<AsmaNameDetailScreen> createState() => _AsmaNameDetailScreenState();
}

class _AsmaNameDetailScreenState extends State<AsmaNameDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _isBuffering = false;
        });
      }
    });
  }

  Future<void> _togglePlay(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) return;
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isBuffering = true);
    try {
      await _player.setUrl(audioUrl);
      await _player.play();
      setState(() {
        _isPlaying = true;
        _isBuffering = false;
      });
    } catch (_) {
      setState(() {
        _isPlaying = false;
        _isBuffering = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9EC),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/asmaDetainImg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Stack(
              children: [
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _OrderBadge(label: widget.name.orderLabel),
                    ),
                    SizedBox(height: 14.h),
                    Expanded(
                      child: BlocBuilder<AsmaNameDetailBloc, AsmaNameDetailState>(
                        builder: (context, state) {
                          switch (state.status) {
                            case AsmaNameDetailStatus.loading:
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            case AsmaNameDetailStatus.failure:
                              return _ErrorView(
                                message: state.failure?.message ?? '',
                                retryLabel: AppText.of(context).tryAgain,
                                onRetry: () => context
                                    .read<AsmaNameDetailBloc>()
                                    .add(LoadAsmaNameDetail(widget.name.id)),
                              );
                            case AsmaNameDetailStatus.success:
                              final detail = state.detail!;
                              return _DetailCard(detail: detail);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 64.h),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: _CircleIconButton(
                      icon: Icons.close,
                      background: Colors.white,
                      iconColor: const Color(0xFFD1212C),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 6.h,
                  child: BlocBuilder<AsmaNameDetailBloc, AsmaNameDetailState>(
                    builder: (context, state) {
                      final audioUrl = state.detail?.audioUrl;
                      return _CircleIconButton(
                        icon: _isBuffering
                            ? null
                            : (_isPlaying ? Icons.pause : Icons.play_arrow),
                        loading: _isBuffering,
                        background: AppColor.primary,
                        iconColor: Colors.white,
                        onTap: audioUrl == null || audioUrl.isEmpty
                            ? null
                            : () => _togglePlay(audioUrl),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.r,
      height: 42.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE1E5C4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: AppColor.authLogo,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.detail});

  final AsmaNameDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 28.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              detail.nameArabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3F6B2C),
                height: 1.5,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              detail.nameTransliteration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColor.authLogo,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              detail.nameBangla,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: AppColor.authHint),
            ),
            SizedBox(height: 8.h),
            Text(
              detail.meaningEnglish,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF93A23A),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              detail.meaningBangla,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF8B9678),
              ),
            ),
            SizedBox(height: 18.h),
            for (final paragraph in detail.explanationParagraphs)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  paragraph.text,
                  textAlign: paragraph.isArabic
                      ? TextAlign.center
                      : TextAlign.start,
                  textDirection: paragraph.isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: paragraph.isArabic
                      ? TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.8,
                          color: const Color(0xFF3F6B2C),
                        )
                      : TextStyle(
                          fontSize: 13.sp,
                          height: 1.6,
                          color: const Color(0xFF4B5540),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.loading = false,
  });

  final IconData? icon;
  final Color background;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 50.r,
        height: 50.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading
            ? SizedBox(
                width: 18.r,
                height: 18.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(icon, color: iconColor, size: 22.sp),
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
