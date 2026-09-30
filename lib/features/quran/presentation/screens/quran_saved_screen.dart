import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';
import 'package:tuhfatul_muslim/core/constants/app_route_observer.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

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
import '../widgets/dashboard/quran_dashboard_header.dart';
import '../widgets/quran_segmented_tabs.dart';

class QuranSavedScreen extends StatefulWidget {
  const QuranSavedScreen({
    super.key,
    this.onBack,
    this.playlistRepository,
    this.active = true,
  });

  final VoidCallback? onBack;
  final QuranPlaylistRepository? playlistRepository;

  /// Whether this tab is the one showing; bookmarks are re-read when it
  /// becomes so, since they are added from the reader.
  final bool active;

  @override
  State<QuranSavedScreen> createState() => _QuranSavedScreenState();
}

class _QuranSavedScreenState extends State<QuranSavedScreen> with RouteAware {
  int _tab = 1; // 0 = Saved, 1 = Play List
  List<Bookmark> _bookmarks = [];
  bool _loadingBookmarks = true;

  late final QuranPlaylistBloc _playlistBloc = QuranPlaylistBloc(
    repository: widget.playlistRepository ?? QuranPlaylistRepositoryImpl.shared,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void didUpdateWidget(QuranSavedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _loadBookmarks();
  }

  // Back from the reader, where bookmarks may have changed.
  @override
  void didPopNext() {
    if (widget.active) _loadBookmarks();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
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
        builder: (_) =>
            CreateQuranPlaylistScreen(repository: widget.playlistRepository),
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
              color: dialogCtx.inkColor(_ink),
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
          floatingActionButton: _tab == 1 ? _createPlaylistButton(t) : null,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: QuranDashboardHeader(
                    title: t.saved,
                    onBack: widget.onBack,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                  child: QuranSegmentedTabs(
                    selected: _tab,
                    labels: [AppText.of(context).bookmarksTitle, t.playList],
                    onSelected: (index) => setState(() => _tab = index),
                  ),
                ),
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

  /// "Create Playlist", styled like the Planner's "Create Plan". The empty
  /// state carries its own button, so this shows once playlists exist.
  Widget? _createPlaylistButton(QuranText t) =>
      BlocBuilder<QuranPlaylistBloc, QuranPlaylistState>(
        builder: (context, state) {
          if (state.playlists.isEmpty) return const SizedBox.shrink();
          return FilledButton.icon(
            key: const ValueKey('quran-create-playlist'),
            onPressed: _openCreatePlaylist,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9EAA52),
              foregroundColor: Colors.white,
              elevation: 3,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.r),
              ),
            ),
            icon: Icon(Icons.playlist_add_rounded, size: 20.sp),
            label: Text(
              t.createPlaylist,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          );
        },
      );

  Widget _buildPlaylistTab(Color borderColor, QuranText t) {
    return BlocBuilder<QuranPlaylistBloc, QuranPlaylistState>(
      builder: (context, state) {
        if (state.status == QuranPlaylistLoadStatus.loading &&
            state.playlists.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9EAA52)),
          );
        }

        if (state.status == QuranPlaylistLoadStatus.failure &&
            state.playlists.isEmpty) {
          return _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: t.somethingWentWrong,
            message: state.failure != null
                ? localizeFailureMessage(state.failure!.message)
                : null,
            action: t.retry,
            actionIcon: Icons.refresh_rounded,
            onAction: () =>
                _playlistBloc.add(const LoadQuranPlaylists(forceRefresh: true)),
          );
        }

        if (state.playlists.isEmpty) {
          return _EmptyState(
            icon: Icons.queue_music_rounded,
            title: t.noPlaylists,
            message: t.emptyPlaylistSub,
            action: t.createPlaylist,
            actionIcon: Icons.playlist_add_rounded,
            onAction: _openCreatePlaylist,
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF7A8D49),
          onRefresh: () async {
            _playlistBloc.add(const LoadQuranPlaylists(forceRefresh: true));
          },
          child: ListView.separated(
            controller: _playlistScrollController,
            // Room at the bottom for the floating "Create Playlist" button.
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
            itemCount: state.playlists.length + (state.isPaginating ? 1 : 0),
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
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
              final progress = pl.totalAyahs > 0
                  ? (pl.percentage / 100).clamp(0.0, 1.0)
                  : 0.0;
              return _SavedCard(
                key: ValueKey('quran-playlist-${pl.id}'),
                icon: Icons.queue_music_rounded,
                title: pl.title,
                subtitle: pl.items.isNotEmpty
                    ? t.playlistSummary([
                        for (final item in pl.items.take(2)) item.surahName,
                      ], pl.items.length)
                    : t.noSurahsInPlaylist,
                onTap: () => _openPlaylist(pl),
                footer: pl.totalAyahs > 0
                    ? Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5.h,
                                color: const Color(0xFF9EAA52),
                                backgroundColor: context.lineColor(
                                  const Color(0xFFE9F0D2),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            '${t.n(pl.percentage.round())}%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: context.inkColor(const Color(0xFF5D7133)),
                            ),
                          ),
                        ],
                      )
                    : null,
                trailing: PopupMenuButton<String>(
                  tooltip: t.delete,
                  onSelected: (val) {
                    if (val == 'delete') _confirmDeletePlaylist(pl);
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
                            style: const TextStyle(color: Color(0xFFC15B4B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20.sp,
                    color: context.inkColor(_muted),
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
      return _EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: t.noBookmarks,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF7A8D49),
      onRefresh: _loadBookmarks,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        itemCount: _bookmarks.length,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final b = _bookmarks[index];
          return _SavedCard(
            icon: Icons.bookmark_rounded,
            title: t.surahName(b.surahNo, b.surahName),
            subtitle:
                '${t.surah} ${t.n(b.surahNo)} • ${t.ayah} ${t.n(b.ayahNo)}',
            onTap: () => _openBookmark(b),
            trailing: Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Icon(
                Icons.chevron_right_rounded,
                color: context.inkColor(const Color(0xFF8FA856)),
                size: 22.sp,
              ),
            ),
          );
        },
      ),
    );
  }
}

const _ink = Color(0xFF2D3A1F);
const _muted = Color(0xFF7C8A63);
const _tint = Color(0xFFEEF3DC);

/// A saved item: icon tile, title and subtitle, an optional footer (such as
/// progress) and a trailing control.
class _SavedCard extends StatelessWidget {
  const _SavedCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.footer,
    this.trailing,
  });

  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final Widget? footer, trailing;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);
    return Material(
      color: context.surfaceColor(Colors.white),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 4.w, 12.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: context.lineColor(const Color(0xFFE3ECC4)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: context.surfaceColor(_tint),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: context.inkColor(const Color(0xFF7A8D49)),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.inkColor(_ink),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.inkColor(_muted),
                      ),
                    ),
                    if (footer != null) ...[SizedBox(height: 8.h), footer!],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered icon, title, optional message and optional action.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message, action;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.r,
              height: 84.r,
              decoration: BoxDecoration(
                color: context.surfaceColor(_tint),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40.sp,
                color: context.inkColor(const Color(0xFF9EAA52)),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.inkColor(_ink),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: 6.h),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.inkColor(_muted),
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: 20.h),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9EAA52),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                ),
                icon: Icon(actionIcon, size: 20.sp),
                label: Text(
                  action!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
