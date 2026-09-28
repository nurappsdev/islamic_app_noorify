import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import '../../data/services/quran_audio_downloader.dart';
import '../../domain/quran_playlist.dart';
import '../../domain/surah_detail.dart';
import '../bloc/reciter/reciter_bloc.dart';
import '../bloc/surah_audio_download/surah_audio_download_bloc.dart';
import '../bloc/surah_playback/surah_playback_bloc.dart';
import '../quran_text.dart';
import '../widgets/quran_player_widgets.dart';

/// Plays a playlist's Surahs one after another through the shared Quran
/// audio engine. Each track gets its own [SurahPlaybackBloc] limited to the
/// item's ayah range; when one finishes the next starts on its own. A Surah
/// whose audio is not on the device prompts for its download first.
class QuranAudioPlayerScreen extends StatefulWidget {
  const QuranAudioPlayerScreen({
    super.key,
    required this.playlist,
    this.initialTrackIndex = 0,
    this.downloader,
  });

  final QuranPlaylist playlist;
  final int initialTrackIndex;
  final QuranAudioDownloader? downloader;

  @override
  State<QuranAudioPlayerScreen> createState() => _QuranAudioPlayerScreenState();
}

class _QuranAudioPlayerScreenState extends State<QuranAudioPlayerScreen> {
  late final QuranAudioDownloader _downloader =
      widget.downloader ?? QuranAudioDownloader();
  late int _currentIndex;
  // Bumped to restart the current track from its first ayah.
  int _generation = 0;

  List<QuranPlaylistItem> get _items => widget.playlist.items;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTrackIndex.clamp(
      0,
      _items.isEmpty ? 0 : _items.length - 1,
    );
  }

  void _selectTrack(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _currentIndex = index;
      _generation++;
    });
  }

  void _restartTrack() => setState(() => _generation++);

  SurahDetail _detailFor(QuranPlaylistItem item) => SurahDetail(
    number: item.surahNo,
    name: item.surahName,
    nameArabic: item.arabicName,
    translation: '',
    revelationPlace: item.revelationPlace,
    totalAyah: item.totalAyah,
    arabicAyahs: const [],
    englishAyahs: const [],
    bengaliAyahs: const [],
  );

  @override
  Widget build(BuildContext context) {
    final body = MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ReciterBloc()..add(const LoadReciters())),
        BlocProvider(
          create: (_) => SurahAudioDownloadBloc(downloader: _downloader),
        ),
      ],
      child: _items.isEmpty
          ? _PlayerView(
              playlist: widget.playlist,
              currentIndex: 0,
              onSelect: _selectTrack,
              onRestart: _restartTrack,
            )
          : Builder(
              builder: (context) {
                final item = _items[_currentIndex];
                final detail = _detailFor(item);
                // A fresh bloc per track (and per restart) so each plays
                // exactly its own ayah range, starting as soon as it opens.
                return BlocProvider(
                  key: ValueKey('track-$_currentIndex-$_generation'),
                  create: (context) =>
                      SurahPlaybackBloc(
                        downloader: _downloader,
                        startAyah: item.startAyah,
                        endAyah: item.endAyah,
                      )..add(
                        PlaySurah(
                          surahNo: item.surahNo,
                          totalAyah: item.totalAyah,
                          recitationId:
                              context.read<ReciterBloc>().state.selectedId ??
                              defaultRecitationId,
                        ),
                      ),
                  child: QuranPlaybackAudioGate(
                    detail: detail,
                    child: BlocListener<SurahPlaybackBloc, SurahPlaybackState>(
                      listenWhen: (p, c) => !p.finished && c.finished,
                      listener: (context, _) {
                        if (_currentIndex < _items.length - 1) {
                          _selectTrack(_currentIndex + 1);
                        }
                      },
                      child: _PlayerView(
                        playlist: widget.playlist,
                        currentIndex: _currentIndex,
                        onSelect: _selectTrack,
                        onRestart: _restartTrack,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(child: body),
    );
  }
}

class _PlayerView extends StatelessWidget {
  const _PlayerView({
    required this.playlist,
    required this.currentIndex,
    required this.onSelect,
    required this.onRestart,
  });

  final QuranPlaylist playlist;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onRestart;

  static const _titleColor = Color(0xFF7A8D49);
  static const _oliveColor = Color(0xFF9EAA52);

  void _togglePlay(BuildContext context, QuranPlaylistItem item) {
    final playback = context.read<SurahPlaybackBloc>();
    final state = playback.state;
    if (state.isPlaying) {
      playback.add(const PauseSurah());
    } else if (state.finished) {
      onRestart();
    } else {
      playback.add(
        PlaySurah(
          surahNo: item.surahNo,
          totalAyah: item.totalAyah,
          recitationId:
              context.read<ReciterBloc>().state.selectedId ??
              defaultRecitationId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = playlist.items;
    final currentItem = items.isNotEmpty ? items[currentIndex] : null;
    final playback = currentItem == null
        ? null
        : context.watch<SurahPlaybackBloc>().state;
    final isPlaying = playback?.isPlaying ?? false;
    final isBuffering = playback?.isBuffering ?? false;
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < items.length - 1;
    final t = QuranText.of(context);

    return Column(
      children: [
        // Top Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
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
              ),
              Text(
                t.quran,
                style: TextStyle(
                  color: _titleColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),

        // Hero Album Card with rich green gradient
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          // Height follows its content, so nothing is cut off on short
          // screens or left empty on tall ones.
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8FA856),
                  Color(0xFF4C754E),
                  Color(0xFF335C3A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4C754E).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Semi-transparent Quran watermark in background
                // Fills the card and scales down with it.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.18,
                    child: FractionallySizedBox(
                      widthFactor: .6,
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/Quran.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Track details
                if (currentItem != null)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 28.h,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.surahName(
                              currentItem.surahNo,
                              currentItem.surahName,
                            ),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: 26.sp,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            width: 140.w,
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '${t.revelationPlace(currentItem.revelationPlace)} • '
                            '${t.ayahRange(currentItem.startAyah, currentItem.endAyah)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 18.h),
                          Image.asset(
                            'assets/images/bismillah.png',
                            height: 36.h,
                            color: Colors.white,
                            fit: BoxFit.contain,
                          ),
                          if (playback != null) ...[
                            SizedBox(height: 14.h),
                            _TrackProgress(item: currentItem, state: playback),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Player Controls (Previous, Play/Pause, Next)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: t.previousSurah,
                onPressed: hasPrevious
                    ? () => onSelect(currentIndex - 1)
                    : null,
                iconSize: 38.sp,
                icon: Icon(
                  Icons.fast_rewind_rounded,
                  color: hasPrevious ? _oliveColor : Colors.grey.shade400,
                ),
              ),
              SizedBox(width: 24.w),
              Semantics(
                button: true,
                label: isPlaying ? t.pause : t.play,
                child: GestureDetector(
                  key: const ValueKey('quran-player-play'),
                  onTap: currentItem == null
                      ? null
                      : () => _togglePlay(context, currentItem),
                  child: Container(
                    width: 68.r,
                    height: 68.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFDEE99D), Color(0xFFB5C96E)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _oliveColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: isPlaying && isBuffering
                        ? Padding(
                            padding: EdgeInsets.all(20.r),
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40.sp,
                          ),
                  ),
                ),
              ),
              SizedBox(width: 24.w),
              IconButton(
                tooltip: t.nextSurah,
                onPressed: hasNext ? () => onSelect(currentIndex + 1) : null,
                iconSize: 38.sp,
                icon: Icon(
                  Icons.fast_forward_rounded,
                  color: hasNext ? _oliveColor : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Bottom Queue List (Playlist Queue)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              border: Border.all(color: const Color(0xFFD2E3A8), width: 1),
            ),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Text(
                  playlist.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 6.h,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(
                      color: const Color(0xFFD2E3A8).withValues(alpha: 0.5),
                      height: 1,
                    ),
                    itemBuilder: (context, i) {
                      final track = items[i];
                      final isCurrent = i == currentIndex;

                      return InkWell(
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Row(
                            children: [
                              // Circled number
                              Container(
                                width: 24.r,
                                height: 24.r,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCurrent
                                        ? _oliveColor
                                        : Colors.grey.shade400,
                                    width: 1.2,
                                  ),
                                  color: isCurrent
                                      ? const Color(0xFFDEE99D)
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  t.n(i + 1),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent
                                        ? const Color(0xFF5D7133)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.surahName(
                                        track.surahNo,
                                        track.surahName,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: isCurrent
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isCurrent
                                            ? _oliveColor
                                            : const Color(0xFF282442),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      t.ayahRange(
                                        track.startAyah,
                                        track.endAyah,
                                      ),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF9090AC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32.r,
                                height: 32.r,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDEE99D),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCurrent && isPlaying
                                      ? Icons.graphic_eq_rounded
                                      : Icons.music_note_rounded,
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Which ayah of the track is playing, with a thin bar across its range.
class _TrackProgress extends StatelessWidget {
  const _TrackProgress({required this.item, required this.state});
  final QuranPlaylistItem item;
  final SurahPlaybackState state;

  @override
  Widget build(BuildContext context) {
    final span = (item.endAyah - item.startAyah + 1).clamp(1, 1 << 30);
    final ayah = state.currentAyahNo;
    final done = state.finished ? span : (ayah - item.startAyah).clamp(0, span);
    final t = QuranText.of(context);
    final label = state.finished
        ? t.finished
        : ayah == 0
        ? t.bismillah
        : t.ayahOf(ayah, item.endAyah);
    // Half the card's width, whatever the screen.
    return FractionallySizedBox(
      widthFactor: .6,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / span,
              minHeight: 3,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
