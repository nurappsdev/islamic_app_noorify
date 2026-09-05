import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_create_folder_sheet.dart';

/// "Book Mark" bottom sheet (design `devImg/img_7.png`): pick (or create) the
/// folder a dua is saved into, then Save. Pops with `true` when a save
/// happened.
///
/// UI only: the folder list and selection live only for the life of this
/// sheet — nothing is persisted, unlike the Hadith feature's
/// [HadithBookmarkSheet].
class DuaBookmarkSheet extends StatefulWidget {
  const DuaBookmarkSheet({super.key, required this.appText});

  final AppText appText;

  @override
  State<DuaBookmarkSheet> createState() => _DuaBookmarkSheetState();
}

class _DuaBookmarkSheetState extends State<DuaBookmarkSheet> {
  final _searchController = TextEditingController();
  List<String> _folders = const ['Favorite'];
  final Set<String> _selected = {'Favorite'};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () =>
          setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DuaCreateFolderSheet(appText: widget.appText),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;
    setState(() {
      if (!_folders.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
        _folders = [..._folders, trimmed];
      }
      _selected.add(trimmed);
    });
  }

  void _save() => Navigator.pop(context, true);

  @override
  Widget build(BuildContext context) {
    final appText = widget.appText;
    final visible = _query.isEmpty
        ? _folders
        : _folders.where((f) => f.toLowerCase().contains(_query)).toList();

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDCE6BE),
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
                color: const Color(0xFFB6C489),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              appText.bookmarkSheetTitle,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3E4A2A),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: appText.searchFolderHint,
                hintStyle: TextStyle(
                  color: const Color(0xFF8A9568),
                  fontSize: 13.sp,
                ),
                isDense: true,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18.sp,
                  color: const Color(0xFF8A9568),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                filled: true,
                fillColor: const Color(0xFFEFF3E1),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: Color(0xFFC7D2A0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: Color(0xFF95A24E)),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 260.h),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 6.h),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final folder = visible[index];
                  final selected = _selected.contains(folder);
                  return InkWell(
                    onTap: () => setState(() {
                      selected
                          ? _selected.remove(folder)
                          : _selected.add(folder);
                    }),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 9.h),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 20.sp,
                            color: selected
                                ? const Color(0xFF7C8A48)
                                : const Color(0xFF9AA77A),
                          ),
                          SizedBox(width: 14.w),
                          Icon(
                            Icons.folder_rounded,
                            size: 22.sp,
                            color: const Color(0xFF8B9A4B),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              folder == 'Favorite'
                                  ? appText.favoriteFolder
                                  : folder,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF3E4A2A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _createFolder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4C5A34),
                      minimumSize: Size(0, 52.h),
                      side: const BorderSide(color: Color(0xFF9BAE6C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.r),
                      ),
                    ),
                    child: Text(
                      appText.createFolderAction,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected.isEmpty ? null : _save,
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
