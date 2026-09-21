import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_read_record.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `17 Aug  At 5 : 35 PM` — the reading-history time style of the design.
String formatHadithReadTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final meridiem = time.hour < 12 ? 'AM' : 'PM';
  return '${time.day} ${_months[time.month - 1]}  At $hour : $minute $meridiem';
}

/// One line of the reading history: the sub-category of the hadith read, in the
/// chosen language, and when it was last read.
class HadithReadRecordRow extends StatelessWidget {
  const HadithReadRecordRow({super.key, required this.record});

  final HadithReadRecord record;

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final readAt = record.lastReadAt;
    return Row(
      children: [
        Container(
          width: 34.r,
          height: 34.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.lineColor(Color(0xFFE3E7D3))),
          ),
          child: Icon(
            Icons.menu_book_outlined,
            size: 16.sp,
            color: context.inkColor(Color(0xFF8B9865)),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            record.title(bangla: isBangla),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: context.inkColor(Color(0xFF2C3320)),
            ),
          ),
        ),
        if (readAt != null) ...[
          SizedBox(width: 10.w),
          Text(
            formatHadithReadTime(readAt),
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFFA1AD59)),
          ),
        ],
      ],
    );
  }
}
