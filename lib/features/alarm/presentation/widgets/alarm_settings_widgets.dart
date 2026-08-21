import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

TextStyle alarmItalicStyle(double size, {Color color = Colors.black}) =>
    TextStyle(
      color: color,
      fontSize: size,
      fontFamily: 'Times New Roman',
      fontStyle: FontStyle.italic,
    );

class AlarmBackHeader extends StatelessWidget {
  const AlarmBackHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF7F5CE),
                foregroundColor: const Color(0xFF526044),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w500),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 3.h),
                Text(
                  subtitle!,
                  style: alarmItalicStyle(11.sp, color: const Color(0xFF9AA687)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AlarmToggleRow extends StatelessWidget {
  const AlarmToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: alarmItalicStyle(14.sp)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF8D9B70),
          activeTrackColor: const Color(0xFFDCE9B8),
          inactiveThumbColor: const Color(0xFFBDBDBD),
          inactiveTrackColor: const Color(0xFFE0E0E0),
        ),
      ],
    );
  }
}

class RingtoneSearchField extends StatelessWidget {
  const RingtoneSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFDCE9B8)),
      ),
      child: Center(
        child: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: 'Search Here . . .',
            hintStyle: alarmItalicStyle(13.sp, color: const Color(0xFF9AA687)),
          ),
          style: alarmItalicStyle(13.sp),
        ),
      ),
    );
  }
}
