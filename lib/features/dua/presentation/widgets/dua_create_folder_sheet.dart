import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// "Create Folder" bottom sheet (design `devImg/img_8.png`), reached from the
/// "Create folder" button on [DuaBookmarkSheet]. Pops with the entered name,
/// or null when cancelled.
class DuaCreateFolderSheet extends StatefulWidget {
  const DuaCreateFolderSheet({super.key, required this.appText});

  final AppText appText;

  @override
  State<DuaCreateFolderSheet> createState() => _DuaCreateFolderSheetState();
}

class _DuaCreateFolderSheetState extends State<DuaCreateFolderSheet> {
  final _controller = TextEditingController();

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
          color: context.surfaceColor(Color(0xFFDCE6BE)),
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
                color: context.surfaceColor(Color(0xFFB6C489)),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              appText.duaCreateFolderTitle,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: context.inkColor(Color(0xFF3E4A2A)),
              ),
            ),
            SizedBox(height: 20.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                appText.folderNameHint,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.inkColor(Color(0xFF5D6B44)),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: appText.duaFolderNameFieldHint,
                hintStyle: TextStyle(
                  color: context.inkColor(Color(0xFF8A9568)),
                  fontSize: 13.sp,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                filled: true,
                fillColor: context.surfaceColor(Color(0xFFEFF3E1)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide(
                    color: context.lineColor(Color(0xFFC7D2A0)),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: Color(0xFF95A24E)),
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
                      foregroundColor: context.inkColor(
                        AppColor.forgotPassword,
                      ),
                      minimumSize: Size(0, 52.h),
                      side: const BorderSide(color: AppColor.forgotPassword),
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
