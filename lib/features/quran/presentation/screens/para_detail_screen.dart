import 'package:flutter/material.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/juz_summary.dart';
import '../quran_route_args.dart';
import '../widgets/quran_design.dart';
import '../widgets/quran_shimmer.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

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
      title: Text(
        context.localizedDigits(
          AppText.of(context).quranParaTitle.fill({'n': widget.number}),
        ),
      ),
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
          return Center(child: Text(AppText.of(context).quranNoSurahs));
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
              context.localizedDigits(
                AppText.of(context).quranParaRange.fill({
                  'count': para.versesCount,
                  'a': para.startSurahNo,
                  'b': para.startAyah,
                  'c': para.endSurahNo,
                  'd': para.endAyah,
                }),
              ),
            ),
            const SizedBox(height: 24),
            for (final surah in para.surahs)
              QuranListRow(
                number: surah.number,
                title: surah.name,
                subtitle: context.localizedDigits(
                  AppText.of(context).quranSurahAyahRange.fill({
                    'name': surah.nameBangla,
                    'from': surah.number == para.startSurahNo
                        ? para.startAyah
                        : 1,
                    'to': surah.number == para.endSurahNo
                        ? para.endAyah
                        : AppText.of(context).quranRangeEnd,
                  }),
                ),
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
