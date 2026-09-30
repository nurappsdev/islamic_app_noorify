import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

/// The Quran module's section switch: equal segments in a soft pill, the
/// selected one filled. Labels shrink to fit rather than being cut short.
class QuranSegmentedTabs extends StatelessWidget {
  const QuranSegmentedTabs({
    super.key,
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  static const _ink = Color(0xFF2D3A1F);
  static const _muted = Color(0xFF6E7B55);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFEEF3DC)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          for (final (index, label) in labels.indexed)
            Expanded(
              child: Semantics(
                button: true,
                selected: index == selected,
                child: GestureDetector(
                  key: ValueKey('quran-segment-$index'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: index == selected
                          ? context.surfaceColor(const Color(0xFFD4E5A8))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: index == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: context.inkColor(
                            index == selected ? _ink : _muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
