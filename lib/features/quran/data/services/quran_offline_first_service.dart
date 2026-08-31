import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';

import 'quran_api_service.dart';
import 'quran_offline_service.dart';

/// The single Quran text source for the app: reads from the on-device SQLite
/// database ([QuranOfflineService]) and only falls back to the network
/// ([QuranApiPagesService]) while that database is still being built on a
/// fresh install. Once the one-time background build has finished, every read
/// is served offline.
class QuranOfflineFirstService implements QuranApiService {
  QuranOfflineFirstService({
    QuranOfflineService? offline,
    QuranApiService? online,
  }) : _offline = offline ?? QuranOfflineService(),
       _online = online ?? QuranApiPagesService();

  final QuranOfflineService _offline;
  final QuranApiService _online;

  @override
  Future<List<SurahSummary>> loadSurahList() async {
    try {
      final list = await _offline.loadSurahList();
      if (list.length >= 114) return list;
    } catch (_) {
      // fall through to the network
    }
    return _online.loadSurahList();
  }

  @override
  Future<SurahDetail> loadSurahDetail(int surahNo) async {
    try {
      final detail = await _offline.loadSurahDetail(surahNo);
      if (detail.arabicAyahs.isNotEmpty) return detail;
    } catch (_) {
      // fall through to the network
    }
    return _online.loadSurahDetail(surahNo);
  }
}
