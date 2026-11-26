import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_bookmark_store.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_saved_folder_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_responsive.dart';
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

  Future<void> _openFolderSettings(String folder) async {
    final details = _folderDetails(folder);
    final action = await showModalBottomSheet<_FolderSettingsAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DuaWebTypography(child: const _FolderSettingsSheet()),
    );
    if (!mounted || action == null) return;

    if (action == _FolderSettingsAction.edit) {
      final value = await _editFolder(_labelFor(folder));
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) _store.renameFolder(folder, trimmed);
    } else if (action == _FolderSettingsAction.info) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) =>
            DuaWebTypography(child: _FolderInfoSheet(details: details)),
      );
    } else {
      final yes = await _confirmDelete();
      if (yes == true) _store.deleteFolder(folder);
    }
  }

  _FolderDetails _folderDetails(String folder) {
    final bookmarks = _store.itemsIn(folder);
    final categories = <String>{
      for (final bookmark in bookmarks)
        context.localized(
          LocalizedText(
            bn: bookmark.categoryNameBn,
            en: bookmark.categoryNameEn,
          ),
        ),
    }..removeWhere((name) => name.isEmpty);
    final dates = bookmarks.map((bookmark) => bookmark.createdAt).toList();
    dates.sort();
    return _FolderDetails(
      duaCount: bookmarks.length,
      categories: categories.toList(),
      createdAt: dates.isEmpty ? null : dates.first,
      lastUpdatedAt: dates.isEmpty ? null : dates.last,
    );
  }

  Future<String?> _editFolder(String value) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DuaWebTypography(child: _EditSheet(initialValue: value)),
    );
  }

  Future<bool?> _confirmDelete() => showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => DuaWebTypography(child: const _DeleteSheet()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            // The whole page - header, count, search and folder list - keeps
            // one centred column, so nothing drifts to the far edges of a
            // desktop window.
            //
            // Capped at [DuaLayout.maxOuter]: every section here pads itself
            // (21px for the folder cards, 30px for the count), so the column
            // is one 16px gutter wider either side and those sections keep
            // the same relation to the nav pill that they have on a phone.
            DuaContentWidth(
              maxWidth: DuaLayout.maxOuter,
              child: Column(
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
                                          onTap: () =>
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      DuaSavedFolderScreen(
                                                        folder: folder,
                                                      ),
                                                ),
                                              ),
                                          onMenu: () =>
                                              _openFolderSettings(folder),
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

enum _FolderSettingsAction { edit, info, delete }

class _FolderDetails {
  const _FolderDetails({
    required this.duaCount,
    required this.categories,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  final int duaCount;
  final List<String> categories;
  final DateTime? createdAt;
  final DateTime? lastUpdatedAt;
}

class _FolderSettingsSheet extends StatelessWidget {
  const _FolderSettingsSheet();

  @override
  Widget build(BuildContext context) => _FolderSheet(
    title: context.localized(
      const LocalizedText(
        en: 'Saved Dua Settings',
        bn: 'সংরক্ষিত দোয়ার সেটিংস',
      ),
    ),
    child: Column(
      children: [
        _SettingsTile(
          icon: Icons.edit_note_rounded,
          iconColor: const Color(0xFFF0A40C),
          iconBackground: const Color(0xFFFFF8E7),
          title: context.localized(
            const LocalizedText(
              en: 'Edit Folder Name',
              bn: 'ফোল্ডারের নাম পরিবর্তন করুন',
            ),
          ),
          subtitle: context.localized(
            const LocalizedText(
              en: 'You can change the folder name',
              bn: 'ফোল্ডারের নাম পরিবর্তন করতে পারবেন',
            ),
          ),
          onTap: () => Navigator.pop(context, _FolderSettingsAction.edit),
        ),
        SizedBox(height: 12.h),
        _SettingsTile(
          icon: Icons.insights_rounded,
          iconColor: const Color(0xFF71873A),
          iconBackground: const Color(0xFFF3F9DD),
          title: context.localized(
            const LocalizedText(en: 'Folder Info', bn: 'ফোল্ডারের তথ্য'),
          ),
          subtitle: context.localized(
            const LocalizedText(
              en: 'Click to see this folder details.',
              bn: 'ফোল্ডারের বিস্তারিত দেখতে ট্যাপ করুন।',
            ),
          ),
          onTap: () => Navigator.pop(context, _FolderSettingsAction.info),
        ),
        SizedBox(height: 12.h),
        _SettingsTile(
          icon: Icons.delete_outline_rounded,
          iconColor: const Color(0xFFFF4E50),
          iconBackground: const Color(0xFFFFE7E8),
          title: context.localized(
            const LocalizedText(en: 'Delete Folder', bn: 'ফোল্ডার মুছুন'),
          ),
          subtitle: context.localized(
            const LocalizedText(
              en: 'Permanently remove folder.',
              bn: 'ফোল্ডারটি স্থায়ীভাবে মুছে ফেলুন।',
            ),
          ),
          color: const Color(0xFFFF4E50),
          onTap: () => Navigator.pop(context, _FolderSettingsAction.delete),
        ),
        SizedBox(height: 26.h),
        _FolderSheetButton(
          label: AppText.of(context).commonDone,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

class _FolderInfoSheet extends StatelessWidget {
  const _FolderInfoSheet({required this.details});

  final _FolderDetails details;

  String _date(BuildContext context, DateTime? value) {
    if (value == null) return '—';
    return context.localizedDigits(
      MaterialLocalizations.of(context).formatMediumDate(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryCount = context.localizedDigits(
      '${details.categories.length}',
    );
    final duaCount = context.localizedDigits('${details.duaCount}');
    return _FolderSheet(
      title: context.localized(
        const LocalizedText(en: 'Folder Info', bn: 'ফোল্ডারের তথ্য'),
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.folder_open_outlined,
            title: context.localized(
              const LocalizedText(
                en: 'Total category into this folder',
                bn: 'এই ফোল্ডারে মোট বিভাগ',
              ),
            ),
            subtitle: context.localized(
              LocalizedText(
                en: 'Total $categoryCount category into this folder',
                bn: 'এই ফোল্ডারে মোট $categoryCountটি বিভাগ',
              ),
            ),
            child: details.categories.isEmpty
                ? null
                : Wrap(
                    spacing: 6.w,
                    runSpacing: 5.h,
                    children: [
                      for (final category in details.categories)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(7.r),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: context.textInkColor(
                                const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          SizedBox(height: 12.h),
          _InfoTile(
            icon: Icons.fact_check_outlined,
            title: context.localized(
              const LocalizedText(
                en: 'Total dua into this folder',
                bn: 'এই ফোল্ডারে মোট দোয়া',
              ),
            ),
            subtitle: context.localized(
              LocalizedText(
                en: 'Total $duaCount dua into this folder',
                bn: 'এই ফোল্ডারে মোট $duaCountটি দোয়া',
              ),
            ),
          ),
          SizedBox(height: 12.h),
          _InfoTile(
            icon: Icons.calendar_month_outlined,
            title: context.localized(
              const LocalizedText(
                en: 'Folder Create Date',
                bn: 'ফোল্ডার তৈরির তারিখ',
              ),
            ),
            subtitle: context.localized(
              LocalizedText(
                en: 'Folder created in ${_date(context, details.createdAt)}',
                bn: 'ফোল্ডার তৈরি হয়েছে ${_date(context, details.createdAt)}',
              ),
            ),
          ),
          SizedBox(height: 12.h),
          _InfoTile(
            icon: Icons.update_rounded,
            title: context.localized(
              const LocalizedText(en: 'Last updated', bn: 'সর্বশেষ হালনাগাদ'),
            ),
            subtitle: context.localized(
              LocalizedText(
                en: 'Saved folder last updated ${_date(context, details.lastUpdatedAt)}',
                bn: 'ফোল্ডারটি সর্বশেষ হালনাগাদ হয়েছে ${_date(context, details.lastUpdatedAt)}',
              ),
            ),
            emphasized: true,
          ),
          SizedBox(height: 26.h),
          _FolderSheetButton(
            label: context.localized(
              const LocalizedText(en: 'Ok', bn: 'ঠিক আছে'),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _FolderSheet extends StatelessWidget {
  const _FolderSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: BoxConstraints(maxHeight: .92.sh),
    padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 18.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(Colors.white),
      borderRadius: BorderRadius.vertical(top: Radius.circular(42.r)),
    ),
    child: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: const Color(0xFFD6D4D3),
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 25.sp,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: context.textInkColor(const Color(0xFFA7B45B)),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                ),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20.sp,
                  color: context.textInkColor(const Color(0xFF777777)),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Ink(
        padding: EdgeInsets.all(13.r),
        decoration: BoxDecoration(
          color: color == null
              ? context.surfaceColor(Colors.white)
              : color!.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(20.r),
          border: color == null
              ? null
              : Border.all(color: color!.withValues(alpha: .22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .025),
              blurRadius: 16.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(icon, color: iconColor, size: 26.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color:
                          color ??
                          context.textInkColor(const Color(0xFF222222)),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: color ?? const Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color ?? const Color(0xFFAAAAAA),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.child,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(16.r),
    decoration: BoxDecoration(
      color: emphasized
          ? const Color(0xFFFBFDF0)
          : context.surfaceColor(Colors.white),
      borderRadius: BorderRadius.circular(20.r),
      border: emphasized ? Border.all(color: const Color(0xFFD9E69A)) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .025),
          blurRadius: 16.r,
          offset: Offset(0, 5.h),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(icon, color: const Color(0xFFB6C66D), size: 27.sp),
        ),
        SizedBox(width: 18.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: emphasized
                      ? const Color(0xFFA5B657)
                      : context.textInkColor(const Color(0xFF242424)),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: emphasized
                      ? const Color(0xFFA5B657)
                      : const Color(0xFF777777),
                ),
              ),
              if (child != null) ...[SizedBox(height: 8.h), child!],
            ],
          ),
        ),
      ],
    ),
  );
}

class _FolderSheetButton extends StatelessWidget {
  const _FolderSheetButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58.h,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFA7B45B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.r),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 17.sp, color: Colors.white),
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
