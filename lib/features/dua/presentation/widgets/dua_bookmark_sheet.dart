import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_bookmark_store.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_create_folder_sheet.dart';

/// "Book Mark" bottom sheet (design `devImg/img_21.png` / `img_22.png`): pick
/// (or create) the folder a dua is saved into, then Save. Pops with `true`
/// when a save happened. Backed by [DuaBookmarkStore] (Hive) — folders and
/// saved duas persist and surface on [DuaSavedScreen].
class DuaBookmarkSheet extends StatefulWidget {
  const DuaBookmarkSheet({
    super.key,
    required this.appText,
    required this.duaId,
    required this.buildSnapshot,
  });

  final AppText appText;

  /// The dua being bookmarked — its own `_id`, or `mock:<name>` for the
  /// legacy catalog's demo duas.
  final String duaId;

  /// Builds the snapshot saved into a given folder.
  final DuaBookmarkModel Function(String folder) buildSnapshot;

  @override
  State<DuaBookmarkSheet> createState() => _DuaBookmarkSheetState();
}

class _DuaBookmarkSheetState extends State<DuaBookmarkSheet> {
  final _searchController = TextEditingController();
  final _folderController = PageController(viewportFraction: 0.34);
  final _store = DuaBookmarkStore.instance;
  late final Set<String> _selected = _initialSelection();
  String _query = '';

  static const _gradientTop = Color(0xFF4C5A34);
  static const _gradientMid = Color(0xFF8B9A4B);
  static const _gradientBottom = Color(0xFFDCE6BE);

  Set<String> _initialSelection() {
    final existing = _store.foldersFor(widget.duaId);
    return existing.isEmpty ? {DuaBookmarkStore.defaultFolder} : existing;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
    if (_folderController.hasClients) _folderController.jumpToPage(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _folderController.dispose();
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
    _store.createFolder(trimmed);
    setState(() => _selected.add(trimmed));
    final folderIndex = _store.folders.indexOf(trimmed);
    if (folderIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_folderController.hasClients) {
          _folderController.animateToPage(
            folderIndex,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _save() {
    _store.saveToFolders(
      duaId: widget.duaId,
      folders: _selected,
      build: widget.buildSnapshot,
    );
    Navigator.pop(context, true);
  }

  void _toggleFolder(String folder) {
    setState(() {
      _selected.contains(folder)
          ? _selected.remove(folder)
          : _selected.add(folder);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appText = widget.appText;
    final folders = _store.folders;
    final visible = _query.isEmpty
        ? folders
        : folders.where((f) => f.toLowerCase().contains(_query)).toList();

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final availableHeight = MediaQuery.of(context).size.height - viewInsets;
    final sheetHeight = (availableHeight * 0.78).clamp(0.0, 620.0).toDouble();

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
          14.h,
          20.w,
          18.h + (viewInsets > 0 ? 0 : safeBottom),
        ),
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            children: [
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                appText.bookmarkSheetTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13.sp, color: Colors.white),
                decoration: InputDecoration(
                  hintText: appText.searchFolderHint,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: .75),
                    fontSize: 13.sp,
                  ),
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18.sp,
                    color: Colors.white.withValues(alpha: .85),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h),
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
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          appText.searchFolderHint,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white.withValues(alpha: .75),
                          ),
                        ),
                      )
                    : PageView.builder(
                        key: ValueKey(visible.join('\n')),
                        controller: _folderController,
                        scrollDirection: Axis.vertical,
                        physics: const BouncingScrollPhysics(),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final folder = visible[index];
                          final count = _store.countIn(folder);
                          return AnimatedBuilder(
                            animation: _folderController,
                            builder: (context, child) {
                              var delta = index.toDouble();
                              if (_folderController.hasClients &&
                                  _folderController.position.haveDimensions) {
                                delta = (_folderController.page ?? 0) - index;
                              }
                              final focus = (1 - delta.abs()).clamp(0.0, 1.0);
                              return Center(
                                child: Opacity(
                                  opacity: 0.28 + (0.72 * focus),
                                  child: Transform.scale(
                                    scale: 0.82 + (0.18 * focus),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: _FolderTile(
                              label: folder == DuaBookmarkStore.defaultFolder
                                  ? appText.favoriteFolder
                                  : folder,
                              countLabel: appText.duaSavedCount.replaceAll(
                                '{n}',
                                context.localizedDigits('$count'),
                              ),
                              selected: _selected.contains(folder),
                              onTap: () => _toggleFolder(folder),
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
                        foregroundColor: context.textInkColor(
                          Color(0xFF4C5A34),
                        ),
                        minimumSize: Size(0, 52.h),
                        side: BorderSide(
                          color: context.lineColor(Color(0xFF9BAE6C)),
                        ),
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
                        '${appText.saveAction} (${context.localizedDigits('${_selected.length}')})',
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
      ),
    );
  }
}

/// One selectable folder row in [DuaBookmarkSheet]'s list (design
/// `devImg/img_21.png` / `img_22.png`): a `folder.svg` icon badge, the
/// folder's name and saved-dua count, and a trailing selection check.
class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.label,
    required this.countLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String countLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(
            Colors.white.withValues(alpha: selected ? 0.95 : 0.85),
          ),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: selected
                ? const Color(0xFFC6A8F5)
                : isDark
                ? const Color(0xFF596344)
                : Colors.white.withValues(alpha: 0.6),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surfaceColor(const Color(0xFFF1F3E2)),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: SvgPicture.asset(
                'assets/svgs/folder.svg',
                width: 24.sp,
                height: 24.sp,
                colorFilter: ColorFilter.mode(
                  context.textInkColor(const Color(0xFF4C5A34)),
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textInkColor(const Color(0xFF2C3320)),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    countLabel,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: context.textInkColor(const Color(0xFF7C8A48)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 24.r,
              height: 24.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF8B9A4B) : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF8B9A4B)
                      : const Color(0xFFB9C488),
                  width: 1.4,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 14.sp, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
