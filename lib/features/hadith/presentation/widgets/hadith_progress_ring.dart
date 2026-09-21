import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_reading_progress/hadith_reading_progress_bloc.dart';

/// The reading progress of one category or sub-category: a ring filled to the
/// backend's `percentage`, with the number inside. Matched by [id] in the
/// nearest [HadithReadingProgressBloc]. Shows 0% when the backend has no
/// progress for it (or the request failed), and an empty ring while the first
/// load is running.
class HadithProgressRing extends StatelessWidget {
  const HadithProgressRing({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    // Rebuild only when this item's own value changes.
    final (isLoading, percentage) = context
        .select<HadithReadingProgressBloc, (bool, double?)>(
          (bloc) => (
            bloc.state.isLoading && bloc.state.progress == null,
            bloc.state.forCategory(id)?.percentage,
          ),
        );
    final clamped = (percentage ?? 0).clamp(0, 100).toDouble();
    final size = 40.r;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            // Full ring = the remaining portion; the arc drawn over it is the
            // read portion.
            value: isLoading ? 0 : clamped / 100,
            strokeWidth: 3.5.r,
            strokeCap: clamped > 0 ? StrokeCap.round : null,
            backgroundColor: context.lineColor(const Color(0xFFE3E7D3)),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF8B9A4B)),
          ),
          if (!isLoading)
            Center(
              child: Text(
                '${clamped.round()}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(const Color(0xFF2C3320)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
