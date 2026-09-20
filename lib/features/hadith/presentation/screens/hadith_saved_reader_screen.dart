import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_bookmark_store.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_content_settings.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_detail_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_detail_screen.dart';

/// Reads a hadith saved from the online library, from the copy kept with its
/// bookmark (so it also works offline). Opened from the Saved screen.
class HadithSavedReaderScreen extends StatefulWidget {
  const HadithSavedReaderScreen({super.key, required this.bookmark});

  final HadithBookmark bookmark;

  @override
  State<HadithSavedReaderScreen> createState() =>
      _HadithSavedReaderScreenState();
}

class _HadithSavedReaderScreenState extends State<HadithSavedReaderScreen> {
  HadithContentSettings _settings = const HadithContentSettings();
  late final HadithDetail? _hadith = _decode(widget.bookmark.payload);

  static HadithDetail? _decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      return HadithDetailModel.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    HadithContentSettingsStore().load().then((value) {
      if (mounted) setState(() => _settings = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final hadith = _hadith;
    final source = hadith == null
        ? ''
        : (hadith.sourceBangla.isNotEmpty
              ? hadith.sourceBangla
              : hadith.sourceEnglish);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            SizedBox(
              height: 44.h,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 14.w, right: 10.w),
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFCBD16B),
                        foregroundColor: const Color(0xFF303629),
                        minimumSize: Size(38.r, 38.r),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${appText.categoryHadith} ${widget.bookmark.hadithNo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.inkColor(const Color(0xFF2C3320)),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                ],
              ),
            ),
            Expanded(
              child: hadith == null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Text(
                          appText.noSavedHadithMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: context.inkColor(const Color(0xFF5D6B44)),
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                      child: HadithDetailCard(
                        hadith: hadith,
                        bookName: source,
                        settings: _settings,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
