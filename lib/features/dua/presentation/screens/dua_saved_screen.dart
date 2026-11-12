import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_bookmark_store.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_saved_folder_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// "Saved" — the Dua feature's bookmark folders (design `devImg/img_16.png`),
/// backed by [DuaBookmarkStore] (Hive): folders and their dua counts persist
/// on-device and update live as bookmarks are added from [DuaReaderScreen].
class DuaSavedScreen extends StatefulWidget {
  const DuaSavedScreen({super.key});

  @override
  State<DuaSavedScreen> createState() => _DuaSavedScreenState();
}

class _DuaSavedScreenState extends State<DuaSavedScreen> {
  final _search = TextEditingController();
  final _store = DuaBookmarkStore.instance;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _labelFor(String folder) => folder == DuaBookmarkStore.defaultFolder
      ? AppText.of(context).favoriteFolder
      : folder;

  Future<void> _menu(String folder) async {
    final action = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(400, 200, 12, 0),
      color: context.surfaceColor(Colors.white),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Text(AppText.readOf(context).duaSavedEdit),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            AppText.readOf(context).duaSavedDelete,
            style: TextStyle(color: context.inkColor(Colors.red)),
          ),
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final value = await _editFolder(_labelFor(folder));
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) _store.renameFolder(folder, trimmed);
    } else {
      final yes = await _confirmDelete();
      if (yes == true) _store.deleteFolder(folder);
    }
  }

  Future<String?> _editFolder(String value) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditSheet(initialValue: value),
    );
  }

  Future<bool?> _confirmDelete() => showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DeleteSheet(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 8.h),
                const _Header(),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) {
                      final query = _search.text.trim().toLowerCase();
                      final folders = [
                        for (final folder in _store.folders)
                          if (query.isEmpty ||
                              _labelFor(folder).toLowerCase().contains(query))
                            folder,
                      ];
                      final appText = AppText.of(context);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(30.w, 12.h, 30.w, 0),
                            child: Text(
                              appText.duaTotalSaved.replaceAll(
                                '{n}',
                                context.localizedDigits(
                                  '${_store.folders.length}',
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: context.textInkColor(
                                  const Color(0xFF252821),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              21.w,
                              10.h,
                              21.w,
                              16.h,
                            ),
                            child: _SearchField(
                              controller: _search,
                              hintText: appText.searchHere,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          Expanded(
                            child: folders.isEmpty
                                ? Center(
                                    child: Text(
                                      appText.noResultsFound,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: context.textInkColor(
                                          const Color(0xFF5D6B44),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.fromLTRB(
                                      21.w,
                                      0,
                                      21.w,
                                      100.h,
                                    ),
                                    itemCount: folders.length,
                                    separatorBuilder: (_, _) =>
                                        SizedBox(height: 10.h),
                                    itemBuilder: (context, index) {
                                      final folder = folders[index];
                                      return _FolderCard(
                                        name: _labelFor(folder),
                                        count: _store.countIn(folder),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DuaSavedFolderScreen(
                                                  folder: folder,
                                                ),
                                          ),
                                        ),
                                        onMenu: () => _menu(folder),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: DuaBottomNav(selectedIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 20.w),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(20.r),
                child: Ink(
                  width: 36.r,
                  height: 36.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9E48C),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16.sp,
                    color: const Color(0xFF667342),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          AppText.of(context).duaSavedTitle,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 23.sp,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: context.textInkColor(const Color(0xFF7D8E54)),
          ),
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: TextStyle(
      fontSize: 13.sp,
      color: context.textInkColor(const Color(0xFF252821)),
    ),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 12.sp,
        color: context.textInkColor(const Color(0xFF989B90)),
      ),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      filled: true,
      fillColor: context.surfaceColor(Colors.white),
      border: _border(context),
      enabledBorder: _border(context),
      focusedBorder: _border(context, focused: true),
    ),
  );

  OutlineInputBorder _border(BuildContext context, {bool focused = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.r),
        borderSide: BorderSide(
          color: context.lineColor(
            focused ? const Color(0xFF9FAF5A) : const Color(0xFFCAD48F),
          ),
          width: focused ? 1.25 : 0.9,
        ),
      );
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.name,
    required this.count,
    required this.onTap,
    required this.onMenu,
  });
  final String name;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22.r),
    child: Container(
      height: 74.h,
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: .22)
                : const Color(0xFF768149).withValues(alpha: .08),
            blurRadius: 18.r,
            offset: Offset(0, 7.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7E9977), Color(0xFFABC77C)],
              ),
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA270D0).withValues(alpha: .24),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Icon(Icons.folder_rounded, size: 31.sp, color: Colors.white),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textInkColor(const Color(0xFF24251F)),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppText.of(context).duaSavedCount.replaceAll(
                    '{n}',
                    context.localizedDigits('$count'),
                  ),
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: context.textInkColor(const Color(0xFF7D7669)),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMenu,
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.textInkColor(const Color(0xFF61594A)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.initialValue});
  final String initialValue;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetShell(
    title: AppText.of(context).duaEditBookmarkTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppText.of(context).duaFolderName,
          style: TextStyle(color: context.textInkColor(Color(0xFF879260))),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: AppText.of(context).duaFolderNameHint,
          ),
        ),
        SizedBox(height: 200.h),
        _Buttons(
          cancel: () => Navigator.pop(context),
          confirm: () => Navigator.pop(context, _controller.text),
          confirmText: AppText.of(context).duaSaveChanges,
        ),
      ],
    ),
  );
}

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet();
  @override
  Widget build(BuildContext context) => _SheetShell(
    title: AppText.of(context).duaDeleteBookmarkTitle,
    child: Column(
      children: [
        Icon(
          Icons.delete_outline,
          color: context.inkColor(Colors.red),
          size: 45.sp,
        ),
        SizedBox(height: 20.h),
        Text(
          AppText.of(context).duaDeleteBookmarkMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textInkColor(const Color(0xFF8B956D)),
          ),
        ),
        SizedBox(height: 130.h),
        _Buttons(
          cancel: () => Navigator.pop(context, false),
          confirm: () => Navigator.pop(context, true),
          confirmText: AppText.of(context).duaYesDelete,
          danger: true,
        ),
      ],
    ),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.surfaceColor(Color(0xFFDCE6BE)),
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            color: context.textInkColor(Color(0xFF879260)),
          ),
        ),
        SizedBox(height: 20.h),
        child,
      ],
    ),
  );
}

class _Buttons extends StatelessWidget {
  const _Buttons({
    required this.cancel,
    required this.confirm,
    required this.confirmText,
    this.danger = false,
  });
  final VoidCallback cancel, confirm;
  final String confirmText;
  final bool danger;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: cancel,
          child: Text(AppText.of(context).duaCancel),
        ),
      ),
      SizedBox(width: 8.w),
      Expanded(
        child: FilledButton(
          onPressed: confirm,
          style: FilledButton.styleFrom(
            backgroundColor: context.surfaceColor(
              danger ? Colors.red.shade700 : const Color(0xFFA5B657),
            ),
          ),
          child: Text(confirmText),
        ),
      ),
    ],
  );
}
