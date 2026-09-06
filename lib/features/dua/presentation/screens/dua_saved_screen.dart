import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_bottom_nav.dart';

class DuaSavedScreen extends StatefulWidget {
  const DuaSavedScreen({super.key});

  @override
  State<DuaSavedScreen> createState() => _DuaSavedScreenState();
}

class _DuaSavedScreenState extends State<DuaSavedScreen> {
  final _search = TextEditingController();
  final _folders = <String>['New folder', 'Prayer', 'Eat', 'Society'];
  final _counts = <int>[7, 20, 17, 11];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _menu(int index) async {
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(190.w, 120.h + index * 78.h, 12.w, 0),
      items: const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final value = await _editFolder(_folders[index]);
      if (value != null && value.trim().isNotEmpty)
        setState(() => _folders[index] = value.trim());
    } else {
      final yes = await _confirmDelete();
      if (yes == true)
        setState(() {
          _folders.removeAt(index);
          _counts.removeAt(index);
        });
    }
  }

  Future<String?> _editFolder(String value) async {
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
    final query = _search.text.toLowerCase();
    final indexes = List<int>.generate(
      _folders.length,
      (i) => i,
    ).where((i) => _folders[i].toLowerCase().contains(query)).toList();
    return Scaffold(
      backgroundColor: Colors.white,
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
                      hintText: 'Search Here . . .',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 13.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.r),
                        borderSide: const BorderSide(color: Color(0xFFB7C86A)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.r),
                        borderSide: const BorderSide(color: Color(0xFFB7C86A)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 90.h),
                    itemCount: indexes.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (_, n) {
                      final i = indexes[n];
                      return _FolderCard(
                        name: _folders[i],
                        count: _counts[i],
                        onMenu: () => _menu(i),
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
          'Saved Hadith',
          style: TextStyle(fontSize: 17.sp, color: const Color(0xFF7D8E54)),
        ),
      ],
    ),
  );
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.name,
    required this.count,
    required this.onMenu,
  });
  final String name;
  final int count;
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) => Container(
    height: 72.h,
    padding: EdgeInsets.symmetric(horizontal: 10.w),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD5E59B)),
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
              name == 'New folder' ? 'Total Saved : 07' : '$count Dua',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFA5B657)),
            ),
          ],
        ),
        const Spacer(),
        IconButton(onPressed: onMenu, icon: const Icon(Icons.more_vert)),
      ],
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
    title: 'Edit Book Mark',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Folder name', style: TextStyle(color: Color(0xFF879260))),
        SizedBox(height: 8.h),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Write Folder Name Here.',
          ),
        ),
        SizedBox(height: 200.h),
        _Buttons(
          cancel: () => Navigator.pop(context),
          confirm: () => Navigator.pop(context, _controller.text),
          confirmText: 'Save Changes',
        ),
      ],
    ),
  );
}

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet();
  @override
  Widget build(BuildContext context) => _SheetShell(
    title: 'Delete Book Mark',
    child: Column(
      children: [
        Icon(Icons.delete_outline, color: Colors.red, size: 45.sp),
        SizedBox(height: 20.h),
        const Text(
          'Are you sure want to delete this\nbookmark right now?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8B956D)),
        ),
        SizedBox(height: 130.h),
        _Buttons(
          cancel: () => Navigator.pop(context, false),
          confirm: () => Navigator.pop(context, true),
          confirmText: 'Yes, Delete',
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
    decoration: const BoxDecoration(
      color: Color(0xFFDCE6BE),
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 17.sp, color: const Color(0xFF879260)),
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
        child: OutlinedButton(onPressed: cancel, child: const Text('Cancel')),
      ),
      SizedBox(width: 8.w),
      Expanded(
        child: FilledButton(
          onPressed: confirm,
          style: FilledButton.styleFrom(
            backgroundColor: danger
                ? Colors.red.shade700
                : const Color(0xFFA5B657),
          ),
          child: Text(confirmText),
        ),
      ),
    ],
  );
}
