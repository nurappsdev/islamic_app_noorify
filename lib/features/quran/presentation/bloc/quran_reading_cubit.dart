import 'package:bloc/bloc.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/quran_ayah.dart';
import '../../domain/surah_summary.dart';

class QuranReadingState {
  const QuranReadingState({
    this.surah,
    this.ayahs = const [],
    this.loading = true,
    this.error = false,
    this.translation = 161,
    this.from = 1,
    this.to = 1,
    this.bismillahPre = false,
    this.pagination,
    this.pages = const [],
  });
  int? get pageNumber => ayahs.isEmpty ? null : ayahs.first.pageNumber;

  final SurahSummary? surah;
  final List<QuranAyah> ayahs;
  final bool loading, error, bismillahPre;
  final int translation, from, to;
  final QuranPagination? pagination;
  final List<int> pages;
}

/// Download batches are independent of Mushaf pages. Only ayahs sharing the
/// requested ayah's pageNumber are displayed, including when that page spans
/// several cached batches or starts before a deep-linked ayah.
class QuranReadingCubit extends Cubit<QuranReadingState> {
  QuranReadingCubit({
    required this.surahNo,
    this.startAyah = 1,
    this.endAyah,
    QuranContentService? service,
  }) : _api = service ?? QuranContentService.shared,
       super(const QuranReadingState());
  final int surahNo, startAyah;
  final int? endAyah;
  final QuranContentService _api;
  static const rangeSize = 16;
  int _generation = 0;
  int? _requestedAyah;
  int get lastAyah => endAyah ?? state.surah?.totalAyah ?? startAyah;

  Future<QuranAyahPage> _batch(int from, int limit, int resource) async {
    final to = (from + rangeSize - 1).clamp(from, limit);
    final response = await _api.loadAyahs(
      surahNo,
      from: from,
      to: to,
      translations: [resource],
    );
    final ayahs = response.pagination.hasNext
        ? await _api.loadRange(
            surahNo,
            from: from,
            to: to,
            translations: [resource],
          )
        : response.ayahs;
    // An incomplete batch must not silently advance past missing ayahs.
    if (ayahs.length != to - from + 1 ||
        ayahs.indexed.any((entry) => entry.$2.ayahNumber != from + entry.$1)) {
      throw const FormatException('Incomplete Quran ayah range');
    }
    return QuranAyahPage(
      surah: response.surah,
      ayahs: ayahs,
      pagination: response.pagination,
      bismillahPre: response.bismillahPre,
      pages: response.pages,
    );
  }

  Future<void> load({int? from, int? translation}) async {
    final generation = ++_generation;
    final first =
        from ??
        (state.error ? _requestedAyah : null) ??
        (state.surah == null ? startAyah : state.from);
    _requestedAyah = first;
    final resource = translation ?? state.translation;
    emit(
      QuranReadingState(
        surah: state.surah,
        ayahs: state.ayahs,
        loading: true,
        translation: resource,
        from: state.from,
        to: state.to,
        bismillahPre: state.bismillahPre,
        pages: state.pages,
      ),
    );
    try {
      final meta = state.surah ?? await _api.loadSurah(surahNo);
      final limit = (endAyah ?? meta.totalAyah).clamp(
        startAyah,
        meta.totalAyah,
      );
      final target = first.clamp(startAyah, limit);
      final batchStart =
          startAyah + ((target - startAyah) ~/ rangeSize) * rangeSize;
      final batch = await _batch(batchStart, limit, resource);
      if (isClosed || generation != _generation) return;
      final pageNumber = batch.ayahs
          .firstWhere((a) => a.ayahNumber == target)
          .pageNumber;
      final visible = batch.ayahs
          .where((a) => a.pageNumber == pageNumber)
          .toList();

      var preceding = batch;
      var precedingStart = batchStart;
      while (precedingStart > startAyah &&
          preceding.ayahs.first.pageNumber == pageNumber) {
        precedingStart = (precedingStart - rangeSize).clamp(startAyah, limit);
        preceding = await _batch(precedingStart, limit, resource);
        if (isClosed || generation != _generation) return;
        visible.insertAll(
          0,
          preceding.ayahs.where((a) => a.pageNumber == pageNumber),
        );
      }
      var following = batch;
      var followingStart = batchStart;
      while (following.ayahs.last.ayahNumber < limit &&
          following.ayahs.last.pageNumber == pageNumber) {
        followingStart += rangeSize;
        following = await _batch(followingStart, limit, resource);
        if (isClosed || generation != _generation) return;
        visible.addAll(
          following.ayahs.where((a) => a.pageNumber == pageNumber),
        );
      }
      emit(
        QuranReadingState(
          surah: meta,
          ayahs: visible,
          loading: false,
          translation: resource,
          from: visible.first.ayahNumber,
          to: visible.last.ayahNumber,
          bismillahPre: batch.bismillahPre,
          pagination: batch.pagination,
          pages: batch.pages,
        ),
      );
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(
        QuranReadingState(
          surah: state.surah,
          ayahs: state.ayahs,
          loading: false,
          error: true,
          translation: resource,
          from: state.from,
          to: state.to,
          bismillahPre: state.bismillahPre,
          pages: state.pages,
        ),
      );
    }
  }

  Future<void> next() async {
    if (state.loading || state.ayahs.isEmpty || state.to >= lastAyah) return;
    await load(from: state.to + 1);
  }

  Future<void> previous() async {
    if (state.loading || state.ayahs.isEmpty || state.from <= startAyah) return;
    await load(from: state.from - 1);
  }
}
