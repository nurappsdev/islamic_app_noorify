import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_bookmark_store.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_saved_folder_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// "Saved" — the Dua feature's bookmark folders (design `devImg/img_9.png`),
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
                _Header(onBack: () => Navigator.maybePop(context)),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: AppText.of(context).searchHere,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 13.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.r),
                        borderSide: BorderSide(
                          color: context.lineColor(Color(0xFFB7C86A)),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.r),
                        borderSide: BorderSide(
                          color: context.lineColor(Color(0xFFB7C86A)),
                        ),
                      ),
                    ),
                  ),
                ),
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
                      if (folders.isEmpty) {
                        return Center(
                          child: Text(
                            AppText.of(context).noResultsFound,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: context.inkColor(Color(0xFF5D6B44)),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 90.h),
                        itemCount: folders.length,
                        separatorBuilder: (_, _) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return _FolderCard(
                            name: _labelFor(folder),
                            count: _store.countIn(folder),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DuaSavedFolderScreen(folder: folder),
                              ),
                            ),
                            onMenu: () => _menu(folder),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: DuaBottomNav(selectedIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE1E56A),
            ),
          ),
        ),
        Text(
          AppText.of(context).duaSavedTitle,
          style: TextStyle(
            fontSize: 17.sp,
            color: context.inkColor(Color(0xFF7D8E54)),
          ),
        ),
      ],
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
    borderRadius: BorderRadius.circular(20.r),
    child: Container(
      height: 72.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        border: Border.all(color: context.lineColor(Color(0xFFD5E59B))),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 22.r, backgroundColor: const Color(0xFFA5B657)),
          SizedBox(width: 10.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 5.h),
              Text(
                AppText.of(context).duaSavedCount.replaceAll(
                  '{n}',
                  context.localizedDigits('$count'),
                ),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFA5B657),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(onPressed: onMenu, icon: const Icon(Icons.more_vert)),
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
          style: TextStyle(color: context.inkColor(Color(0xFF879260))),
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
          style: const TextStyle(color: Color(0xFF8B956D)),
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
            color: context.inkColor(Color(0xFF879260)),
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
