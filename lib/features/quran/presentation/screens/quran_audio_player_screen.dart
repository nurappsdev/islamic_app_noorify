import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import '../../domain/quran_playlist.dart';

class QuranAudioPlayerScreen extends StatefulWidget {
  const QuranAudioPlayerScreen({
    super.key,
    required this.playlist,
    this.initialTrackIndex = 0,
  });

  final QuranPlaylist playlist;
  final int initialTrackIndex;

  @override
  State<QuranAudioPlayerScreen> createState() => _QuranAudioPlayerScreenState();
}

class _QuranAudioPlayerScreenState extends State<QuranAudioPlayerScreen> {
  late int _currentIndex;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTrackIndex.clamp(
      0,
      widget.playlist.items.isEmpty ? 0 : widget.playlist.items.length - 1,
    );
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
  }

  void _previousTrack() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isPlaying = true;
      });
    }
  }

  void _nextTrack() {
    if (_currentIndex < widget.playlist.items.length - 1) {
      setState(() {
        _currentIndex++;
        _isPlaying = true;
      });
    }
  }

  void _selectTrack(int index) {
    setState(() {
      _currentIndex = index;
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.playlist.items;
    final currentItem = items.isNotEmpty ? items[_currentIndex] : null;

    const titleColor = Color(0xFF7A8D49);
    const oliveColor = Color(0xFF9EAA52);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
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
                    'Quran',
                    style: TextStyle(
                      color: titleColor,
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
              child: Container(
                height: 250.h,
                width: double.infinity,
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
                    Positioned(
                      bottom: -10.h,
                      child: Opacity(
                        opacity: 0.18,
                        child: Image.asset(
                          'assets/images/Quran.png',
                          width: 220.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Track details
                    if (currentItem != null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentItem.surahName,
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
                            '${currentItem.revelationPlace} • Ayat ${currentItem.startAyah}-${currentItem.endAyah}',
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
                        ],
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
                    onPressed: _currentIndex > 0 ? _previousTrack : null,
                    iconSize: 38.sp,
                    icon: Icon(
                      Icons.fast_rewind_rounded,
                      color: _currentIndex > 0
                          ? oliveColor
                          : Colors.grey.shade400,
                    ),
                  ),
                  SizedBox(width: 24.w),
                  GestureDetector(
                    onTap: _togglePlayPause,
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
                            color: oliveColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w),
                  IconButton(
                    onPressed: _currentIndex < items.length - 1
                        ? _nextTrack
                        : null,
                    iconSize: 38.sp,
                    icon: Icon(
                      Icons.fast_forward_rounded,
                      color: _currentIndex < items.length - 1
                          ? oliveColor
                          : Colors.grey.shade400,
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
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32.r),
                  ),
                  border: Border.all(color: const Color(0xFFD2E3A8), width: 1),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    Text(
                      widget.playlist.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
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
                          final isCurrent = i == _currentIndex;

                          return InkWell(
                            onTap: () => _selectTrack(i),
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
                                            ? oliveColor
                                            : Colors.grey.shade400,
                                        width: 1.2,
                                      ),
                                      color: isCurrent
                                          ? const Color(0xFFDEE99D)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      '${i + 1}',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.surahName,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: isCurrent
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isCurrent
                                                ? oliveColor
                                                : const Color(0xFF282442),
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          'Ayat ${track.startAyah}-${track.endAyah}',
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
