import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_preference.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

import '../../data/repositories/quran_playlist_repository_impl.dart';
import '../../domain/quran_playlist.dart';
import '../../domain/repositories/quran_playlist_repository.dart';
import '../quran_text.dart';
import '../widgets/quran_surah_picker_sheet.dart';

class CreateQuranPlaylistScreen extends StatefulWidget {
  const CreateQuranPlaylistScreen({
    super.key,
    this.repository,
    this.initialPlaylist,
  });

  final QuranPlaylistRepository? repository;
  final QuranPlaylist? initialPlaylist;

  bool get isEditing => initialPlaylist != null;

  @override
  State<CreateQuranPlaylistScreen> createState() =>
      _CreateQuranPlaylistScreenState();
}

class _CreateQuranPlaylistScreenState extends State<CreateQuranPlaylistScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  final List<QuranPlaylistItem> _items = [];
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPlaylist;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    if (p != null) {
      _items.addAll(p.items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addSurah() async {
    final t = QuranText.read(context);
    final selected = await QuranSurahPickerSheet.show(
      context,
      title: t.addSurah,
    );
    if (selected != null && mounted) {
      setState(() {
        _items.add(
          QuranPlaylistItem(
            type: 'surah',
            surahNumber: selected.number,
            title: selected.name,
            surahNameEnglish: selected.name,
            surahNameArabic: selected.nameArabic,
            revelationPlace: selected.revelationPlace,
            fromAyah: 1,
            toAyah: selected.totalAyah > 0 ? selected.totalAyah : 1,
            totalAyahs: selected.totalAyah > 0 ? selected.totalAyah : 1,
          ),
        );
        _errorMessage = null;
      });
    }
  }

  Future<void> _addPara() async {
    final t = QuranText.read(context);
    final paraNumber = await showDialog<int>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: dialogCtx.surfaceColor(Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            t.addPara,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF282442),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 280.h,
            child: ListView.separated(
              itemCount: 30,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final num = index + 1;
                return ListTile(
                  title: Text(
                    '${t.juz} ${t.n(num)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF302647),
                    ),
                  ),
                  onTap: () => Navigator.pop(dialogCtx, num),
                );
              },
            ),
          ),
        );
      },
    );

    if (paraNumber != null && mounted) {
      setState(() {
        _items.add(
          QuranPlaylistItem(
            type: 'para',
            paraNumber: paraNumber,
            title: '${t.juz} ${t.n(paraNumber)}',
            surahNameEnglish: 'Para $paraNumber',
            surahNameBangla: 'পারা $paraNumber',
            totalAyahs: 0,
          ),
        );
        _errorMessage = null;
      });
    }
  }

  Future<void> _addAyahsRange() async {
    final t = QuranText.read(context);
    final selected = await QuranSurahPickerSheet.show(
      context,
      title: t.addAyahsRange,
    );
    if (selected == null || !mounted) return;

    final fromController = TextEditingController(text: '1');
    final toController = TextEditingController(
      text: selected.totalAyah > 0 ? selected.totalAyah.toString() : '7',
    );

    final range = await showDialog<(int, int)>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: dialogCtx.surfaceColor(Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            '${selected.name} - ${t.ayahRangeLabel}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF282442),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fromController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.fromAyah,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: toController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.toAyah,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () {
                final f = int.tryParse(fromController.text.trim()) ?? 1;
                final to =
                    int.tryParse(toController.text.trim()) ?? selected.totalAyah;
                Navigator.pop(dialogCtx, (f, to));
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7A8D49),
              ),
              child: Text(t.add),
            ),
          ],
        );
      },
    );

    if (range != null && mounted) {
      final from = math.max(1, range.$1);
      final to = math.max(from, range.$2);
      final total = to - from + 1;
      setState(() {
        _items.add(
          QuranPlaylistItem(
            type: 'ayahs',
            surahNumber: selected.number,
            title: '${selected.name} ($from-$to)',
            surahNameEnglish: selected.name,
            surahNameArabic: selected.nameArabic,
            revelationPlace: selected.revelationPlace,
            fromAyah: from,
            toAyah: to,
            totalAyahs: total,
          ),
        );
        _errorMessage = null;
      });
    }
  }

  void _removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    final t = QuranText.read(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = t.enterPlaylistName);
      return;
    }
    if (_items.isEmpty) {
      setState(() => _errorMessage = t.selectAtLeastOneItem);
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final repo = widget.repository ?? QuranPlaylistRepositoryImpl.shared;
    final itemInputs = _items.map(PlaylistItemInput.fromPlaylistItem).toList();
    final description = _descriptionController.text.trim();

    if (widget.isEditing) {
      final req = UpdateQuranPlaylistRequest(
        name: name,
        description: description.isNotEmpty ? description : null,
        items: itemInputs,
      );
      final result = await repo.updatePlaylist(widget.initialPlaylist!.id, req);
      if (!mounted) return;
      setState(() => _submitting = false);
      result.fold(
        (failure) {
          final message = (failure.statusCode == 409)
              ? localizeFailureMessage('you already have a playlist with this name')
              : localizeFailureMessage(failure.message);
          setState(() => _errorMessage = message);
        },
        (updatedPlaylist) {
          Navigator.of(context).pop(updatedPlaylist);
        },
      );
    } else {
      final req = CreateQuranPlaylistRequest(
        name: name,
        description: description.isNotEmpty ? description : null,
        items: itemInputs,
      );
      final result = await repo.createPlaylist(req);
      if (!mounted) return;
      setState(() => _submitting = false);
      result.fold(
        (failure) {
          final message = (failure.statusCode == 409)
              ? localizeFailureMessage('you already have a playlist with this name')
              : localizeFailureMessage(failure.message);
          setState(() => _errorMessage = message);
        },
        (createdPlaylist) {
          Navigator.of(context).pop(createdPlaylist);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF7A8D49);
    const borderColor = Color(0xFFD2E3A8);
    const oliveColor = Color(0xFF9EAA52);
    final t = QuranText.of(context);
    final langCode =
        LanguagePreference.current == AppLanguage.bangla ? 'bn' : 'en';

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDEE99D),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: const Color(0xFF5D7133),
                        size: 26.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      widget.isEditing ? t.editPlaylist : t.createPlaylist,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor.withValues(alpha: 0.6), height: 1),

            // Form Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Name Field
                  Text(
                    t.playlistName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF332A66),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: t.playlistNameHint,
                      hintStyle: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF9090AC),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FBF4),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(
                          color: oliveColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Description Field
                  Text(
                    t.playlistDescription,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF332A66),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: t.playlistDescriptionHint,
                      hintStyle: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF9090AC),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FBF4),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(
                          color: oliveColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Items Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${t.surahs} / ${t.paras}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF332A66),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'surah') _addSurah();
                          if (val == 'para') _addPara();
                          if (val == 'range') _addAyahsRange();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'surah',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF7A8D49),
                                  size: 18,
                                ),
                                SizedBox(width: 8.w),
                                Text(t.addSurah),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'para',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bookmark_border_rounded,
                                  color: Color(0xFF7A8D49),
                                  size: 18,
                                ),
                                SizedBox(width: 8.w),
                                Text(t.addPara),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'range',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.format_list_numbered_rounded,
                                  color: Color(0xFF7A8D49),
                                  size: 18,
                                ),
                                SizedBox(width: 8.w),
                                Text(t.addAyahsRange),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEE99D),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18.sp,
                                color: const Color(0xFF5D7133),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                t.addItem,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5D7133),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Items List
                  if (_items.isEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 36.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF4),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.playlist_add_rounded,
                            size: 40.sp,
                            color: const Color(0xFFB5C96E),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            t.noItemsInPlaylist,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF9090AC),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _items.removeAt(oldIndex);
                          _items.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Container(
                          key: ValueKey('${item.type}_${item.surahNumber}_${item.fromAyah}_$index'),
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBF4),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: borderColor.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.drag_handle_rounded,
                                color: const Color(0xFF8FA856),
                                size: 20.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.localizedName(langCode),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF302647),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      item.type == 'para'
                                          ? '${t.juz} ${t.n(item.paraNumber ?? 1)}'
                                          : (item.type == 'ayahs'
                                              ? '${t.ayah} ${t.n(item.fromAyah)}-${t.n(item.toAyah)}'
                                              : '${t.revelationPlace(item.revelationPlace)} • ${t.ayahCount(item.totalAyah)}'),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF9090AC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18.sp,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  SizedBox(height: 24.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7A8D49),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: _submitting
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isEditing ? t.update : t.create,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
