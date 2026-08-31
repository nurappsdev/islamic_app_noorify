import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_bookmark_store.dart';

/// "Book Mark" bottom sheet: pick (or create) the folders a hadith is saved
/// into, then Save. Pops with `true` when a save happened.
class HadithBookmarkSheet extends StatefulWidget {
  const HadithBookmarkSheet({
    super.key,
    required this.bookmark,
    required this.appText,
  });

  final HadithBookmark bookmark;
  final AppText appText;

  @override
  State<HadithBookmarkSheet> createState() => _HadithBookmarkSheetState();
}

class _HadithBookmarkSheetState extends State<HadithBookmarkSheet> {
  final _store = HadithBookmarkStore();
  final _searchController = TextEditingController();

  List<String> _folders = const [];
  final Set<String> _selected = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final folders = await _store.folders();
    final current = await _store.foldersFor(
      widget.bookmark.bookSlug,
      widget.bookmark.hadithNo,
    );
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _selected
        ..clear()
        ..addAll(
          current.isEmpty ? const {HadithBookmarkStore.defaultFolder} : current,
        );
      _loading = false;
    });
  }

  Future<void> _createFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CreateFolderDialog(appText: widget.appText),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    await _store.createFolder(trimmed);
    if (!mounted) return;
    final folders = await _store.folders();
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _selected.add(
        folders.firstWhere(
          (f) => f.toLowerCase() == trimmed.toLowerCase(),
          orElse: () => trimmed,
        ),
      );
    });
  }

  Future<void> _save() async {
    await _store.saveToFolders(widget.bookmark, _selected);
    if (mounted) Navigator.pop(context, true);
  }

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
              child: _loading
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 28.h),
                      child: const CircularProgressIndicator(
                        color: AppColor.primary,
                      ),
                    )
                  : ListView.builder(
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
                                    folder,
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

class _CreateFolderDialog extends StatefulWidget {
  const _CreateFolderDialog({required this.appText});

  final AppText appText;

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    final appText = widget.appText;
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        appText.createFolderAction,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: appText.folderNameHint,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColor.primary),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
          child: Text(appText.create),
        ),
      ],
    );
  }
}
