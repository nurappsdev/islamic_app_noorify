import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../domain/quran_playlist.dart';
import '../quran_text.dart';
import 'quran_audio_player_screen.dart';

class QuranPlaylistDetailScreen extends StatelessWidget {
  const QuranPlaylistDetailScreen({super.key, required this.playlist});

  final QuranPlaylist playlist;

  void _openPlayer(BuildContext context, [int trackIndex = 0]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranAudioPlayerScreen(
          playlist: playlist,
          initialTrackIndex: trackIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF7A8D49);
    const borderColor = Color(0xFFD2E3A8);
    final t = QuranText.of(context);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Back button, Title, "Play All" pill
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
                  InkWell(
                    onTap: () => _openPlayer(context, 0),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_outlined,
                            size: 20.sp,
                            color: titleColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            t.playAll,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor.withValues(alpha: 0.6), height: 1),

            // Surahs List in this playlist
            Expanded(
              child: playlist.items.isEmpty
                  ? Center(
                      child: Text(
                        t.noSurahsInPlaylist,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.sp,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      itemCount: playlist.items.length,
                      separatorBuilder: (_, _) => Divider(
                        color: borderColor.withValues(alpha: 0.4),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = playlist.items[index];
                        return InkWell(
                          onTap: () => _openPlayer(context, index),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.surahName(
                                          item.surahNo,
                                          item.surahName,
                                        ),
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
                                        '${t.revelationPlace(item.revelationPlace)} • '
                                        '${t.ayahCount(item.endAyah - item.startAyah + 1)}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF9090AC),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Arabic Name
                                if (item.arabicName.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    child: Text(
                                      item.arabicName,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontFamily: 'Noorehuda',
                                        fontSize: 18.sp,
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
                      },
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
