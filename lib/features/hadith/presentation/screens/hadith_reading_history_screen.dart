import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// Full reading-history list, reached from "See All" on [HadithDashboardScreen].
///
/// Two tabs — hadith reads and e-book reads. Static mock entries for now.
class HadithReadingHistoryScreen extends StatefulWidget {
  const HadithReadingHistoryScreen({super.key});

  @override
  State<HadithReadingHistoryScreen> createState() =>
      _HadithReadingHistoryScreenState();
}

class _HadithReadingHistoryScreenState
    extends State<HadithReadingHistoryScreen> {
  int _tab = 0;

  static const _entries = <String>[
    '17 Aug  At 5 : 35 PM',
    '17 Aug  At 5 : 35 PM',
    '17 Aug  At 5 : 35 PM',
    '17 Aug  At 5 : 35 PM',
    '17 Aug  At 5 : 35 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final label = _tab == 0 ? appText.categoryHadith : appText.ebookLabel;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _Header(title: appText.readingHistoryTitle),
            SizedBox(height: 18.h),
            _HistoryTabs(
              selected: _tab,
              hadithLabel: appText.categoryHadith,
              ebookLabel: appText.ebookLabel,
              onChanged: (t) => setState(() => _tab = t),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
                itemCount: _entries.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 22.h, color: const Color(0xFFEDEFE0)),
                itemBuilder: (context, index) =>
                    _HistoryRow(label: label, timestamp: _entries[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

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
              padding: EdgeInsets.only(left: 14.w),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFCBD16B),
                  foregroundColor: const Color(0xFF303629),
                  minimumSize: Size(38.r, 38.r),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColor.authLogo,
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs({
    required this.selected,
    required this.hadithLabel,
    required this.ebookLabel,
    required this.onChanged,
  });

  final int selected;
  final String hadithLabel;
  final String ebookLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _tab(hadithLabel, 0),
          _tab(ebookLabel, 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDDE8BA) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border(
              bottom: BorderSide(
                color: active ? Colors.transparent : const Color(0xFFC7D2A0),
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: active
                  ? const Color(0xFF3E4A2A)
                  : const Color(0xFF2C3320),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.timestamp});

  final String label;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34.r,
          height: 34.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE3E7D3)),
          ),
          child: Icon(
            Icons.menu_book_outlined,
            size: 16.sp,
            color: const Color(0xFF8B9865),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2C3320),
          ),
        ),
        const Spacer(),
        Text(
          timestamp,
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFFA1AD59),
          ),
        ),
      ],
    );
  }
}
