import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_preference.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

import '../../data/repositories/quran_playlist_repository_impl.dart';
import '../../domain/quran_playlist.dart';
import '../../domain/repositories/quran_playlist_repository.dart';
import '../bloc/quran_playlist/quran_playlist_bloc.dart';
import '../quran_route_args.dart';
import '../quran_text.dart';
import 'create_quran_playlist_screen.dart';
import 'quran_audio_player_screen.dart';

class QuranPlaylistDetailScreen extends StatefulWidget {
  const QuranPlaylistDetailScreen({
    super.key,
    required this.playlist,
    this.repository,
    this.bloc,
  });

  final QuranPlaylist playlist;
  final QuranPlaylistRepository? repository;
  final QuranPlaylistBloc? bloc;

  @override
  State<QuranPlaylistDetailScreen> createState() =>
      _QuranPlaylistDetailScreenState();
}

class _QuranPlaylistDetailScreenState extends State<QuranPlaylistDetailScreen> {
  late final QuranPlaylistBloc _bloc =
      widget.bloc ??
      QuranPlaylistBloc(
        repository: widget.repository ?? QuranPlaylistRepositoryImpl.shared,
      );

  @override
  void initState() {
    super.initState();
    _bloc.add(
      LoadQuranPlaylistDetails(
        playlistId: widget.playlist.id,
        forceRefresh: true,
      ),
    );
  }

  @override
  void dispose() {
    if (widget.bloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  void _openPlayer(
    BuildContext context,
    QuranPlaylist playlist, [
    int trackIndex = 0,
  ]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranAudioPlayerScreen(
          playlist: playlist,
          initialTrackIndex: trackIndex,
        ),
      ),
    );
  }

  Future<void> _openEditPlaylist(QuranPlaylist playlist) async {
    final t = QuranText.read(context);
    final updated = await Navigator.of(context).push<QuranPlaylist>(
      MaterialPageRoute(
        builder: (_) => CreateQuranPlaylistScreen(
          repository: widget.repository,
          initialPlaylist: playlist,
        ),
      ),
    );
    if (updated != null && mounted) {
      _bloc.add(
        LoadQuranPlaylistDetails(
          playlistId: playlist.id,
          forceRefresh: true,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.playlistUpdatedSuccessfully),
          backgroundColor: const Color(0xFF6B8042),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDelete(QuranPlaylist playlist) async {
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
      _bloc.add(DeleteQuranPlaylist(playlistId: playlist.id));
    }
  }

  void _continueReading(QuranPlaylistNextAyah nextAyah) {
    Navigator.of(context)
        .pushNamed(
          RouteNames.quranSurahDetail,
          arguments: SurahRouteArgs(
            surahNo: nextAyah.surahNumber,
            surahName: nextAyah.surahNameEnglish,
            ayahNo: nextAyah.ayahNumber,
            paraNumber: nextAyah.paraNumber,
          ),
        )
        .then((_) {
          if (mounted) {
            _bloc.add(
              LoadQuranPlaylistDetails(
                playlistId: widget.playlist.id,
                forceRefresh: true,
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF7A8D49);
    const borderColor = Color(0xFFD2E3A8);
    final t = QuranText.of(context);
    final langCode =
        LanguagePreference.current == AppLanguage.bangla ? 'bn' : 'en';

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<QuranPlaylistBloc, QuranPlaylistState>(
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
            Navigator.of(context).pop();
            return;
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
        builder: (context, state) {
          final playlist =
              state.selectedPlaylistDetails ?? widget.playlist;

          return Scaffold(
            backgroundColor: context.pageColor(Colors.white),
            body: SafeArea(
              child: Column(
                children: [
                  // Top Header: Back button, Title, "Play All" pill, Options Menu
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
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
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            playlist.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // "Play All" pill button
                        if (playlist.items.isNotEmpty) ...[
                          InkWell(
                            onTap: () => _openPlayer(context, playlist, 0),
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_outlined,
                                    size: 18.sp,
                                    color: titleColor,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    t.playAll,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],
                        // Options menu (Edit, Delete)
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              _openEditPlaylist(playlist);
                            } else if (val == 'delete') {
                              _confirmDelete(playlist);
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Color(0xFF5D7133),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(t.editPlaylist),
                                ],
                              ),
                            ),
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
                          child: Container(
                            width: 36.r,
                            height: 36.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0F5E2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.more_vert_rounded,
                              color: const Color(0xFF5D7133),
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: borderColor.withValues(alpha: 0.6), height: 1),

                  // Content Area
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFF7A8D49),
                      onRefresh: () async {
                        _bloc.add(
                          LoadQuranPlaylistDetails(
                            playlistId: playlist.id,
                            forceRefresh: true,
                          ),
                        );
                      },
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        children: [
                          // Hero Progress Card (if has ayahs)
                          if (playlist.totalAyahs > 0)
                            _buildProgressCard(playlist, t),

                          // Next Ayah Card ("Continue Reading")
                          if (playlist.nextAyah != null && !playlist.isCompleted)
                            _buildNextAyahCard(playlist.nextAyah!, t, langCode),

                          // Playlist Description if present
                          if (playlist.description != null &&
                              playlist.description!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: 12.h,
                                top: 4.h,
                              ),
                              child: Text(
                                playlist.description!,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF5D6B44),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          // Section Header
                          Padding(
                            padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${t.surahs} (${t.n(playlist.items.length)})',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF332A66),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Items List
                          if (playlist.items.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.h),
                              child: Center(
                                child: Text(
                                  t.noSurahsInPlaylist,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...List.generate(playlist.items.length, (index) {
                              final item = playlist.items[index];
                              return Column(
                                children: [
                                  _buildItemTile(
                                    context,
                                    item,
                                    index,
                                    playlist,
                                    t,
                                    langCode,
                                    borderColor,
                                  ),
                                  if (index < playlist.items.length - 1)
                                    Divider(
                                      color: borderColor.withValues(alpha: 0.4),
                                      height: 1,
                                    ),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(QuranPlaylist playlist, QuranText t) {
    final pct = playlist.percentage.clamp(0.0, 100.0);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F2CC), Color(0xFFF4F8DE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFD2E3A8), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.progress,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF332A66),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A8D49),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${t.n(pct.toInt())}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 8.h,
              backgroundColor: const Color(0xFFD2E3A8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7A8D49),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Progress counts row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressMetric(
                t.completed,
                '${t.n(playlist.completedAyahs)} ${t.ayah}',
                const Color(0xFF5D7133),
              ),
              _buildProgressMetric(
                t.remaining,
                '${t.n(playlist.remainingAyahs)} ${t.ayah}',
                const Color(0xFF9090AC),
              ),
              _buildProgressMetric(
                t.totalAyahs,
                '${t.n(playlist.totalAyahs)} ${t.ayah}',
                const Color(0xFF332A66),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF7D7D99)),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNextAyahCard(
    QuranPlaylistNextAyah nextAyah,
    QuranText t,
    String langCode,
  ) {
    final surahTitle =
        langCode == 'bn' && nextAyah.surahNameBangla.isNotEmpty
            ? nextAyah.surahNameBangla
            : (langCode == 'ar' && nextAyah.surahNameArabic.isNotEmpty
                ? nextAyah.surahNameArabic
                : nextAyah.surahNameEnglish);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF8),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD2E3A8)),
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: const BoxDecoration(
              color: Color(0xFFDEE99D),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: const Color(0xFF5D7133),
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.nextAyah,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8FA856),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$surahTitle • ${t.ayah} ${t.n(nextAyah.ayahNumber)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF332A66),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _continueReading(nextAyah),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF7A8D49),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.continueReading,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14.sp,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    QuranPlaylistItem item,
    int index,
    QuranPlaylist playlist,
    QuranText t,
    String langCode,
    Color borderColor,
  ) {
    return InkWell(
      onTap: () => _openPlayer(context, playlist, index),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            // 16-point star badge
            SizedBox(
              width: 38.r,
              height: 38.r,
              child: CustomPaint(
                painter: _PlaylistStarPainter(),
                child: Center(
                  child: Text(
                    t.n(index + 1),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5D7133),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.localizedName(langCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.amiri(
                      fontSize: 17.sp,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF302647),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    item.type == 'para'
                        ? '${t.juz} ${t.n(item.paraNumber ?? 1)}'
                        : (item.type == 'ayahs'
                            ? '${t.ayah} ${t.n(item.fromAyah)}-${t.n(item.toAyah)} • ${t.revelationPlace(item.revelationPlace)}'
                            : '${t.revelationPlace(item.revelationPlace)} • '
                                '${t.ayahCount(item.endAyah - item.startAyah + 1)}'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9090AC),
                    ),
                  ),
                ],
              ),
            ),

            // Progress badge (if item progress is tracked)
            if (item.isCompleted)
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.all(4.r),
                decoration: const BoxDecoration(
                  color: Color(0xFF7A8D49),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
              )
            else if (item.readAyahs > 0 && item.totalAyahs > 0)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  '${t.n(item.percentage.toInt())}%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7A8D49),
                  ),
                ),
              ),

            // Arabic Name
            if (item.arabicName.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  item.arabicName,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Noorehuda',
                    fontSize: 17.sp,
                    color: const Color(0xFF7A8D49),
                  ),
                ),
              ),

            // Music note button
            Container(
              width: 36.r,
              height: 36.r,
              decoration: const BoxDecoration(
                color: Color(0xFFDEE99D),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.queue_music_rounded,
                color: const Color(0xFF5D7133),
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + i * math.pi / 8;
      final radius = size.width * (i.isEven ? .48 : .36);
      final point = Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height / 2 + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD4E5A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
