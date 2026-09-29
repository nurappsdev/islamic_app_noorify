import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

import '../../data/repositories/quran_playlist_repository_impl.dart';
import '../../data/services/quran_local_store.dart';
import '../../domain/bookmark.dart';
import '../../domain/quran_playlist.dart';
import '../../domain/repositories/quran_playlist_repository.dart';
import '../bloc/quran_playlist/quran_playlist_bloc.dart';
import '../quran_route_args.dart';
import '../quran_text.dart';
import 'create_quran_playlist_screen.dart';
import 'quran_playlist_detail_screen.dart';

class QuranSavedScreen extends StatefulWidget {
  const QuranSavedScreen({super.key, this.onBack, this.playlistRepository});

  final VoidCallback? onBack;
  final QuranPlaylistRepository? playlistRepository;

  @override
  State<QuranSavedScreen> createState() => _QuranSavedScreenState();
}

class _QuranSavedScreenState extends State<QuranSavedScreen> {
  int _tab = 1; // 0 = Saved, 1 = Play List
  List<Bookmark> _bookmarks = [];
  bool _loadingBookmarks = true;

  late final QuranPlaylistBloc _playlistBloc = QuranPlaylistBloc(
    repository:
        widget.playlistRepository ?? QuranPlaylistRepositoryImpl.shared,
  );

  final ScrollController _playlistScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _playlistBloc.add(const LoadQuranPlaylists());
    _playlistScrollController.addListener(_onPlaylistScroll);
  }

  void _onPlaylistScroll() {
    if (_playlistScrollController.position.pixels >=
        _playlistScrollController.position.maxScrollExtent - 200) {
      _playlistBloc.add(const LoadMoreQuranPlaylists());
    }
  }

  @override
  void dispose() {
    _playlistScrollController.dispose();
    _playlistBloc.close();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    List<Bookmark> bookmarks = [];
    try {
      final store = await QuranLocalStore.create();
      bookmarks = await store.bookmarks();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _loadingBookmarks = false;
      });
    }
  }

  void _openPlaylist(QuranPlaylist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranPlaylistDetailScreen(
          playlist: playlist,
          repository: widget.playlistRepository,
        ),
      ),
    );
  }

  Future<void> _openCreatePlaylist() async {
    final t = QuranText.read(context);
    final created = await Navigator.of(context).push<QuranPlaylist>(
      MaterialPageRoute(
        builder: (_) => CreateQuranPlaylistScreen(
          repository: widget.playlistRepository,
        ),
      ),
    );
    if (created != null && mounted) {
      _playlistBloc.add(const LoadQuranPlaylists(forceRefresh: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.playlistCreatedSuccessfully),
          backgroundColor: const Color(0xFF6B8042),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeletePlaylist(QuranPlaylist playlist) async {
    final t = QuranText.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: dialogCtx.surfaceColor(Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            t.deletePlaylistConfirmTitle,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF282442),
            ),
          ),
          content: Text(
            t.deletePlaylistConfirmMessage,
            style: TextStyle(
              fontSize: 13.sp,
              color: dialogCtx.inkColor(const Color(0xFF5D6B44)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC15B4B),
              ),
              child: Text(t.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      _playlistBloc.add(DeleteQuranPlaylist(playlistId: playlist.id));
    }
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

    return BlocProvider.value(
      value: _playlistBloc,
      child: BlocListener<QuranPlaylistBloc, QuranPlaylistState>(
        listenWhen: (previous, current) =>
            (!previous.deleteSuccess && current.deleteSuccess) ||
            (previous.deleteFailure != current.deleteFailure &&
                current.deleteFailure != null),
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.deleteSuccess) {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(t.playlistDeletedSuccessfully),
                backgroundColor: const Color(0xFF6B8042),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.deleteFailure != null) {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  localizeFailureMessage(state.deleteFailure!.message),
                ),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: context.pageColor(Colors.white),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 8.h),
                // Top Tabs: "Saved" and "Play List" + Create button if tab == 1
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
                      const Spacer(),
                      if (_tab == 1)
                        InkWell(
                          onTap: _openCreatePlaylist,
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEE99D),
                              borderRadius: BorderRadius.circular(14.r),
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
                                  t.create,
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
                ),

                // Tab Content
                Expanded(
                  child: _tab == 1
                      ? _buildPlaylistTab(borderColor, t)
                      : _buildSavedTab(borderColor, t),
                ),
              ],
            ),
          ),
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
    return BlocBuilder<QuranPlaylistBloc, QuranPlaylistState>(
      builder: (context, state) {
        if (state.status == QuranPlaylistLoadStatus.loading &&
            state.playlists.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF9EAA52),
            ),
          );
        }

        if (state.status == QuranPlaylistLoadStatus.failure &&
            state.playlists.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48.sp,
                    color: Colors.red.shade400,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    state.failure != null
                        ? localizeFailureMessage(state.failure!.message)
                        : t.somethingWentWrong,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  FilledButton.icon(
                    onPressed: () {
                      _playlistBloc.add(
                        const LoadQuranPlaylists(forceRefresh: true),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A8D49),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(t.retry),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.playlists.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 54.sp,
                    color: const Color(0xFFB5C96E),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    t.noPlaylists,
                    style: TextStyle(
                      color: const Color(0xFF332A66),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    t.emptyPlaylistSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  FilledButton.icon(
                    onPressed: _openCreatePlaylist,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A8D49),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      t.createPlaylist,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF7A8D49),
          onRefresh: () async {
            _playlistBloc.add(const LoadQuranPlaylists(forceRefresh: true));
          },
          child: ListView.separated(
            controller: _playlistScrollController,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: state.playlists.length + (state.isPaginating ? 1 : 0),
            separatorBuilder: (_, _) =>
                Divider(color: borderColor.withValues(alpha: 0.5), height: 1),
            itemBuilder: (context, index) {
              if (index >= state.playlists.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF7A8D49),
                    ),
                  ),
                );
              }

              final pl = state.playlists[index];
              return InkWell(
                onTap: () => _openPlaylist(pl),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Row(
                    children: [
                      // Left music icon
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
                              pl.items.isNotEmpty
                                  ? t.playlistSummary([
                                      for (final item in pl.items.take(2))
                                        item.surahName,
                                    ], pl.items.length)
                                  : t.noSurahsInPlaylist,
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

                      // Progress badge if has ayahs
                      if (pl.totalAyahs > 0 && pl.percentage > 0)
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2CC),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: const Color(0xFFD2E3A8),
                            ),
                          ),
                          child: Text(
                            '${t.n(pl.percentage.toInt())}%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5D7133),
                            ),
                          ),
                        ),

                      // Options popup menu
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'delete') {
                            _confirmDeletePlaylist(pl);
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFC15B4B),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  t.delete,
                                  style: const TextStyle(
                                    color: Color(0xFFC15B4B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 20.sp,
                            color: const Color(0xFF9090AC),
                          ),
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
          ),
        );
      },
    );
  }

  Widget _buildSavedTab(Color borderColor, QuranText t) {
    if (_loadingBookmarks) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9EAA52)),
      );
    }

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
        return InkWell(
          onTap: () => _openBookmark(b),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark_rounded,
                  color: const Color(0xFF8FA856),
                  size: 26.sp,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.surahName(b.surahNo, b.surahName),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF332A66),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${t.surah} ${t.n(b.surahNo)} • ${t.ayah} ${t.n(b.ayahNo)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF9090AC),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF8FA856),
                  size: 22.sp,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
