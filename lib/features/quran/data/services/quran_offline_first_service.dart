import '../../domain/surah_detail.dart';
import '../../domain/surah_summary.dart';
import 'quran_api_service.dart';
import 'quran_offline_service.dart';

/// Compatibility facade; internal responses include a persistent recent cache.
class QuranOfflineFirstService implements QuranApiService {
  QuranOfflineFirstService({
    QuranOfflineService? offline,
    QuranApiService? online,
  }) : _online = online ?? InternalQuranApiService();
  final QuranApiService _online;
  @override
  Future<List<SurahSummary>> loadSurahList() => _online.loadSurahList();
  @override
  Future<SurahDetail> loadSurahDetail(int surahNo) =>
      _online.loadSurahDetail(surahNo);
}
