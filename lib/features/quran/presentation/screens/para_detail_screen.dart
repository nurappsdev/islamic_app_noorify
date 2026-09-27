import 'package:flutter/material.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/juz_summary.dart';
import '../quran_route_args.dart';
import '../widgets/quran_design.dart';
import '../widgets/quran_shimmer.dart';

class ParaDetailScreen extends StatefulWidget {
  const ParaDetailScreen({super.key, required this.number});
  final int number;
  @override
  State<ParaDetailScreen> createState() => _ParaDetailScreenState();
}

class _ParaDetailScreenState extends State<ParaDetailScreen> {
  late Future<JuzSummary> _future = QuranContentService.shared.loadPara(
    widget.number,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.pageColor(Colors.white),
    appBar: AppBar(
      title: Text('Para ${widget.number}'),
      foregroundColor: quranInk,
      backgroundColor: context.pageColor(quranPale),
    ),
    body: FutureBuilder<JuzSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return QuranRetry(
            onRetry: () => setState(
              () =>
                  _future = QuranContentService.shared.loadPara(widget.number),
            ),
          );
        }
        if (!snapshot.hasData) return const SurahListShimmer();
        final para = snapshot.requireData;
        if (para.surahs.isEmpty) {
          return const Center(child: Text('No surahs available'));
        }
        return ListView(
          padding: const EdgeInsets.all(19),
          children: [
            Text(
              para.nameBangla,
              style: const TextStyle(fontSize: 24, color: quranInk),
            ),
            const SizedBox(height: 8),
            Text(
              '${para.versesCount} ayahs · ${para.startSurahNo}:${para.startAyah} – ${para.endSurahNo}:${para.endAyah}',
            ),
            const SizedBox(height: 24),
            for (final surah in para.surahs)
              QuranListRow(
                number: surah.number,
                title: surah.name,
                subtitle:
                    '${surah.nameBangla}\nAyah ${surah.number == para.startSurahNo ? para.startAyah : 1} – ${surah.number == para.endSurahNo ? para.endAyah : 'end'}',
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.quranSurahDetail,
                  arguments: SurahRouteArgs(
                    surahNo: surah.number,
                    surahName: surah.name,
                    ayahNo: surah.number == para.startSurahNo
                        ? para.startAyah
                        : 1,
                    endAyah: surah.number == para.endSurahNo
                        ? para.endAyah
                        : null,
                    paraNumber: para.number,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
