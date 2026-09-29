import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../domain/quran_playlist.dart';
import '../../domain/bookmark.dart';
import '../../data/services/quran_playlist_store.dart';
import '../../data/services/quran_local_store.dart';
import '../quran_route_args.dart';
import '../quran_text.dart';
import 'quran_playlist_detail_screen.dart';

class QuranSavedScreen extends StatefulWidget {
  const QuranSavedScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<QuranSavedScreen> createState() => _QuranSavedScreenState();
}

class _QuranSavedScreenState extends State<QuranSavedScreen> {
  int _tab = 1; // 0 = Saved, 1 = Play List (matches Screenshot 2 default)
  List<QuranPlaylist> _playlists = [];
  List<Bookmark> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final playlists = await QuranPlaylistStore.loadPlaylists();
    List<Bookmark> bookmarks = [];
    try {
      final store = await QuranLocalStore.create();
      bookmarks = await store.bookmarks();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _playlists = playlists;
        _bookmarks = bookmarks;
        _loading = false;
      });
    }
  }

  void _openPlaylist(QuranPlaylist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranPlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _openBookmark(Bookmark b) {
    Navigator.of(context).pushNamed(
      RouteNames.quranSurahDetail,
      arguments: SurahRouteArgs(
        surahNo: b.surahNo,
        ayahNo: b.ayahNo,
        surahName: b.surahName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFD2E3A8);
    final t = QuranText.of(context);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            // Top Tabs: "Saved" and "Play List"
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Flexible(child: _buildTab(index: 0, title: t.saved)),
                  SizedBox(width: 12.w),
                  Flexible(child: _buildTab(index: 1, title: t.playList)),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9EAA52),
                      ),
                    )
                  : _tab == 1
                  ? _buildPlaylistTab(borderColor, t)
                  : _buildSavedTab(borderColor, t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({required int index, required String title}) {
    final isSelected = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4E5A8) : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF232D1C)
                : const Color(0xFF4A553E),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistTab(Color borderColor, QuranText t) {
    if (_playlists.isEmpty) {
      return Center(
        child: Text(
          t.noPlaylists,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _playlists.length,
      separatorBuilder: (_, _) =>
          Divider(color: borderColor.withValues(alpha: 0.5), height: 1),
      itemBuilder: (context, index) {
        final pl = _playlists[index];
        return InkWell(
          onTap: () => _openPlaylist(pl),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              children: [
                // Left music icon with plus
                Icon(
                  Icons.queue_music_rounded,
                  color: const Color(0xFF8FA856),
                  size: 28.sp,
                ),
                SizedBox(width: 16.w),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pl.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF332A66),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        t.playlistSummary([
                          for (final item in pl.items.take(2))
                            t.surahName(item.surahNo, item.surahName),
                        ], pl.items.length),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF9090AC),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing circular music note button
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDEE99D),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: const Color(0xFF5D7133),
                    size: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedTab(Color borderColor, QuranText t) {
    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 54.sp,
              color: const Color(0xFFB5C96E),
            ),
            SizedBox(height: 12.h),
            Text(
              t.noBookmarks,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _bookmarks.length,
      separatorBuilder: (_, _) =>
          Divider(color: borderColor.withValues(alpha: 0.5), height: 1),
      itemBuilder: (context, index) {
        final b = _bookmarks[index];
        return ListTile(
          onTap: () => _openBookmark(b),
          leading: Container(
            width: 38.r,
            height: 38.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFDEE99D),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_rounded,
              color: const Color(0xFF5D7133),
              size: 20.sp,
            ),
          ),
          title: Text(
            t.surahName(b.surahNo, b.surahName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF332A66),
            ),
          ),
          subtitle: Text(
            t.ayahLabel(b.ayahNo),
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9090AC)),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF8FA856),
          ),
        );
      },
    );
  }
}
