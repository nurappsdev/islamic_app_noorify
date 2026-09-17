import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';
import 'package:islami_app_noorify/features/asma_husna/presentation/widgets/asma_scallop_badge.dart';

class AsmaNameCard extends StatelessWidget {
  const AsmaNameCard({
    super.key,
    required this.name,
    required this.isPlaying,
    required this.isBuffering,
    required this.onTogglePlay,
    required this.onShowDetails,
  });

  static const _arabicGreen = Color(0xFF3F6B2C);
  static const _oliveGreen = Color(0xFF93A23A);
  static const _sageText = Color(0xFF8B9678);


  static const _outerCardFill = Color(0xFFF6F8EC);
  static const _circleFillLight = Color(0xFFF2F4E1);
  static const _circleFillDark = Color(0xFFE1E5C4);
  static const _playGradientStart = Color(0xFFA9BC5C);
  static const _playGradientEnd = Color(0xFF748C3A);

  final AsmaName name;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback? onTogglePlay;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      decoration: BoxDecoration(
        color: _outerCardFill,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: const Color(0xFFD8E2B0).withValues(alpha: 0.4),
        ),
        image: const DecorationImage(
          image: AssetImage('assets/asmaulHusnas.png'),
          fit: BoxFit.cover,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 18.h),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: .92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name.nameArabic,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w700,
                                color: _arabicGreen,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              name.nameTransliteration,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 19.sp,
                                fontWeight: FontWeight.w700,
                                color: _oliveGreen,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              name.meaningBangla,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontStyle: FontStyle.italic,
                                color: _sageText,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _DetailsPill(
                              label: appText.asmaHusnaClickDetails,
                              onTap: onShowDetails,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _EmbossedCircle(
                      size: 42.r,
                      gradientStart: _circleFillLight,
                      gradientEnd: _circleFillDark,
                      child: Text(
                        name.orderLabel,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _oliveGreen,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onTogglePlay,
                      customBorder: const CircleBorder(),
                      child: _EmbossedCircle(
                        size: 46.r,
                        gradientStart: _playGradientStart,
                        gradientEnd: _playGradientEnd,
                        child: isBuffering
                            ? SizedBox(
                                width: 18.r,
                                height: 18.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPill extends StatelessWidget {
  const _DetailsPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: const Color(0xFFD7DEB2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF7C8863),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmbossedCircle extends StatelessWidget {
  const _EmbossedCircle({
    required this.size,
    required this.gradientStart,
    required this.gradientEnd,
    required this.child,
  });

  final double size;
  final Color gradientStart;
  final Color gradientEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: child,
    );
  }
}
