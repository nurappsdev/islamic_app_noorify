import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// "Create Folder" bottom sheet (design `devImg/img_23.png`), reached from the
/// "Create folder" / "Add more" actions on [DuaBookmarkSheet]. Pops with the
/// entered name, or null when cancelled.
class DuaCreateFolderSheet extends StatefulWidget {
  const DuaCreateFolderSheet({super.key, required this.appText});

  final AppText appText;

  @override
  State<DuaCreateFolderSheet> createState() => _DuaCreateFolderSheetState();
}

class _DuaCreateFolderSheetState extends State<DuaCreateFolderSheet> {
  final _controller = TextEditingController();

  static const _gradientTop = Color(0xFF4C5A34);
  static const _gradientMid = Color(0xFF8B9A4B);
  static const _gradientBottom = Color(0xFFDCE6BE);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _controller.text);
  void _cancel() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final appText = widget.appText;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.surfaceColor(_gradientTop),
              context.surfaceColor(_gradientMid),
              context.surfaceColor(_gradientBottom),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        padding: EdgeInsets.fromLTRB(
          20.w,
          12.h,
          20.w,
          18.h + (viewInsets > 0 ? 0 : safeBottom),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              appText.duaCreateFolderTitle,
              style: TextStyle(
                fontSize: 19.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 18.h),
            SvgPicture.asset(
              'assets/svgs/folder.svg',
              width: 128.w,
              height: 116.h,
            ),
            SizedBox(height: 22.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                appText.folderNameHint,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: .9),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              style: TextStyle(fontSize: 13.sp, color: Colors.white),
              decoration: InputDecoration(
                hintText: appText.duaFolderNameFieldHint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 13.sp,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: .14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: .45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: .85),
                  ),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            SizedBox(height: 28.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 52.h),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .7),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.r),
                      ),
                    ),
                    child: Text(
                      appText.duaCancel,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF95A24E),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 52.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.r),
                      ),
                    ),
                    child: Text(
                      appText.saveAction,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
