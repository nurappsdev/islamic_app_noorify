import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_content_service.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/quran_reading_cubit.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_reading_navigation.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_route_args.dart';
import 'package:tuhfatul_muslim/features/quran/domain/translation_edition.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final FutureOr<Map<String, Object?>> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(await respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> ok(Object data, {Object? meta}) => {
  'success': true,
  'data': data,
  'meta': meta,
};
final surah = <String, Object?>{
  'number': 2,
  'nameEnglish': 'Al-Baqarah',
  'nameArabic': 'البقرة',
  'nameBangla': 'আল-বাকারা',
  'ayahCount': 286,
  'revelationType': 'medinan',
};
Map<String, Object?> ayah(int n, {int resource = 161}) => {
  'surahNumber': 2,
  'ayahNumber': n,
  'verseKey': '2:$n',
  'ayahIndex': n + 7,
  'paraNumber': 3,
  'pageNumber': 42,
  'textArabic': 'تِلْكَ اٰیٰتُ اللّٰهِ',
  'translations': [
    {
      'resourceId': 20,
      'name': 'Saheeh International',
      'authorName': 'Saheeh International',
      'textPlain': 'English',
    },
    {
      'resourceId': resource,
      'name': 'Taisirul Quran',
      'authorName': 'Tawheed Publication',
      'textPlain': 'এসব আল্লাহরই আয়াত',
    },
  ],
};
Map<String, Object?> page(
  List<Map<String, Object?>> ayahs, {
  int number = 1,
  int pages = 1,
}) => ok(
  {
    'surah': {
      ...surah,
      'surahNumber': 2,
      'bismillahPre': true,
      'pages': [2, 49],
    },
    'ayahs': ayahs,
  },
  meta: {'page': number, 'limit': ayahs.length, 'total': 6, 'totalPage': pages},
);
QuranContentService service(Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return QuranContentService(client: DioClient(dio: dio), persistCache: false);
}

void main() {
  test(
    'adjacent Surah navigation is sequential and carries the timer',
    () async {
      final adapter = Adapter((request) {
        final number = int.parse(request.path.split('/').last);
        return ok({
          ...surah,
          'number': number,
          'nameEnglish': 'Surah $number',
          'ayahCount': number == 1
              ? 7
              : number == 2
              ? 286
              : 200,
        });
      });
      final api = service(adapter);
      final session = QuranReadingSession();
      const second = SurahRouteArgs(surahNo: 2, surahName: 'Al-Baqarah');

      final next = await adjacentSurahArgs(
        service: api,
        current: second,
        session: session,
        forward: true,
      );
      expect([next!.surahNo, next.ayahNo], [3, 1]);
      expect(next.readingSession, same(session));
      expect(next.swipeForward, isTrue);
      final previous = await adjacentSurahArgs(
        service: api,
        current: second,
        session: session,
        forward: false,
      );
      expect([previous!.surahNo, previous.ayahNo], [1, 7]);
      expect(previous.readingSession, same(session));
      expect(previous.swipeForward, isFalse);
      expect(adapter.requests.map((request) => request.path), [
        '/quran/surahs/3',
        '/quran/surahs/1',
      ]);

      expect(
        await adjacentSurahArgs(
          service: api,
          current: const SurahRouteArgs(surahNo: 1, surahName: ''),
          session: session,
          forward: false,
        ),
        isNull,
      );
      expect(
        await adjacentSurahArgs(
          service: api,
          current: const SurahRouteArgs(surahNo: 114, surahName: ''),
          session: session,
          forward: true,
        ),
        isNull,
      );
      expect(
        await adjacentSurahArgs(
          service: api,
          current: const SurahRouteArgs(
            surahNo: 2,
            surahName: '',
            paraNumber: 1,
          ),
          session: session,
          forward: true,
        ),
        isNull,
      );
      expect(adapter.requests.length, 2);
      expect(second.withReadingSession(session).readingSession, same(session));
    },
  );
  test(
    'catalog and para use internal envelopes and preserve exact boundaries',
    () async {
      final adapter = Adapter(
        (r) => r.path.endsWith('/surahs')
            ? ok([surah])
            : ok({
                'number': 3,
                'nameBangla': 'পারা ৩',
                'start': {'surah': 2, 'ayah': 253},
                'end': {'surah': 3, 'ayah': 92},
                'ayahCount': 126,
                'surahs': [
                  {
                    'number': 2,
                    'nameEnglish': 'Al-Baqarah',
                    'nameBangla': 'আল-বাকারা',
                  },
                ],
              }),
      );
      final api = service(adapter);
      expect((await api.loadSurahs()).single.number, 2);
      final para = await api.loadPara(3);
      expect(
        [para.startSurahNo, para.startAyah, para.endSurahNo, para.endAyah],
        [2, 253, 3, 92],
      );
      expect(para.surahs.single.name, 'Al-Baqarah');
      expect(
        adapter.requests.every((r) => r.path.startsWith('/quran/')),
        isTrue,
      );
    },
  );
  test('translation lookup uses resource ID, never response order', () async {
    final adapter = Adapter((_) => page([ayah(255)]));
    final result = await service(
      adapter,
    ).loadAyahs(2, from: 255, to: 255, translations: [161, 20]);
    expect(result.ayahs.single.translations[161]!.text, 'এসব আল্লাহরই আয়াত');
    expect(result.ayahs.single.translations[20]!.text, 'English');
    expect(adapter.requests.single.queryParameters['translations'], '161,20');
    expect(result.ayahs.single.verseKey, '2:255');
    expect(result.ayahs.single.pageNumber, 42);
  });
  test(
    'range follows meta pagination and deduplicates overlapping verses',
    () async {
      final adapter = Adapter(
        (r) => r.queryParameters['page'] == 1
            ? page([ayah(252), ayah(253)], pages: 2)
            : page([ayah(253), ayah(254)], number: 2, pages: 2),
      );
      final api = service(adapter);
      final result = await api.loadRange(2, from: 252, to: 254);
      expect(result.map((a) => a.ayahNumber), [252, 253, 254]);
      expect(adapter.requests.map((r) => r.queryParameters['page']), [1, 2]);
      await api.loadRange(2, from: 252, to: 254);
      expect(adapter.requests.length, 2);
    },
  );
  test('invalid pagination terminates with an error', () async {
    final api = service(Adapter((_) => page([], pages: 2)));
    await expectLater(api.loadRange(2, from: 1, to: 5), throwsFormatException);
  });
  test(
    'failed responses are retried and concurrent requests are shared',
    () async {
      var count = 0;
      final adapter = Adapter((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return ++count == 1 ? {'success': false, 'data': null} : ok([surah]);
      });
      final api = service(adapter);
      await expectLater(api.loadSurahs(), throwsFormatException);
      await Future.wait([api.loadSurahs(), api.loadSurahs()]);
      expect(count, 2);
    },
  );
  test(
    'reader bounds requests to Para, preserves position on translation switch',
    () async {
      final adapter = Adapter((r) {
        if (!r.path.endsWith('ayahs')) return ok(surah);
        return page([
          for (
            var n = r.queryParameters['from'] as int;
            n <= (r.queryParameters['to'] as int);
            n++
          )
            ayah(n),
        ]);
      });
      final bloc = QuranReadingCubit(
        surahNo: 2,
        startAyah: 253,
        endAyah: 257,
        service: service(adapter),
      );
      addTearDown(bloc.close);
      await bloc.load();
      expect(bloc.state.from, 253);
      expect(bloc.state.to, 257);
      await bloc.load(translation: 162);
      expect(bloc.state.from, 253);
      expect(adapter.requests.last.queryParameters['translations'], '162');
      expect(adapter.requests.last.queryParameters['to'], 257);
    },
  );
  test('slow old translation cannot overwrite newer selection', () async {
    final delayed = Completer<Map<String, Object?>>();
    final adapter = Adapter((r) {
      if (!r.path.endsWith('ayahs')) return ok(surah);
      if (r.queryParameters['translations'] == '162') return delayed.future;
      return page([for (var n = 1; n <= 7; n++) ayah(n)]);
    });
    final bloc = QuranReadingCubit(
      surahNo: 2,
      endAyah: 7,
      service: service(adapter),
    );
    addTearDown(bloc.close);
    await bloc.load();
    final slow = bloc.load(translation: 162);
    await bloc.load(translation: 20);
    delayed.complete(
      page([for (var n = 1; n <= 7; n++) ayah(n, resource: 162)]),
    );
    await slow;
    expect(bloc.state.translation, 20);
  });
  test(
    'catalog is dynamic and legacy preference IDs map to internal resources',
    () async {
      final api = service(
        Adapter(
          (_) => ok([
            {
              'resourceId': 213,
              'name': 'Dr. Abu Bakr Muhammad Zakaria',
              'authorName': 'Author',
              'languageCode': null,
            },
            {
              'resourceId': 161,
              'name': 'Taisirul Quran',
              'authorName': 'Tawheed Publication',
            },
          ]),
        ),
      );
      final editions = await api.loadTranslations();
      expect(editions.map((e) => e.resourceId), [213, 161]);
      expect(resourceIdForEdition(editions.last.id), 161);
      expect(resourceIdForEdition('english'), 20);
    },
  );
  test(
    'turns actual pages sequentially and jumps to the complete page',
    () async {
      final adapter = Adapter((r) {
        if (!r.path.endsWith('ayahs')) return ok(surah);
        return page([
          for (
            var n = r.queryParameters['from'] as int;
            n <= (r.queryParameters['to'] as int);
            n++
          )
            {
              ...ayah(n),
              'pageNumber': n <= 5
                  ? 2
                  : n <= 16
                  ? 3
                  : n <= 24
                  ? 4
                  : 5,
            },
        ]);
      });
      final bloc = QuranReadingCubit(
        surahNo: 2,
        endAyah: 40,
        service: service(adapter),
      );
      addTearDown(bloc.close);
      await bloc.load();
      expect(
        [bloc.state.pageNumber, bloc.state.from, bloc.state.to],
        [2, 1, 5],
      );
      await bloc.next();
      expect(
        [bloc.state.pageNumber, bloc.state.from, bloc.state.to],
        [3, 6, 16],
      );
      await bloc.next();
      expect(
        [bloc.state.pageNumber, bloc.state.from, bloc.state.to],
        [4, 17, 24],
      );
      await bloc.previous();
      expect(
        [bloc.state.pageNumber, bloc.state.from, bloc.state.to],
        [3, 6, 16],
      );
      await bloc.load(from: 19);
      expect(
        [bloc.state.pageNumber, bloc.state.from, bloc.state.to],
        [4, 17, 24],
      );
      await bloc.next();
      expect(
        [bloc.state.pageNumber, bloc.state.from, bloc.state.to],
        [5, 25, 40],
      );
      expect(bloc.state.ayahs.every((a) => a.pageNumber == 5), isTrue);
      expect(adapter.requests.where((r) => r.path.endsWith('ayahs')).length, 3);
    },
  );
  test(
    'failed turn retains current page and retries the intended page',
    () async {
      var fail = true;
      final adapter = Adapter((r) {
        if (!r.path.endsWith('ayahs')) return ok(surah);
        if (r.queryParameters['from'] == 17 && fail) {
          return {'success': false};
        }
        return page([
          for (
            var n = r.queryParameters['from'] as int;
            n <= (r.queryParameters['to'] as int);
            n++
          )
            {
              ...ayah(n),
              'pageNumber': n <= 5
                  ? 2
                  : n <= 20
                  ? 3
                  : 4,
            },
        ]);
      });
      final bloc = QuranReadingCubit(
        surahNo: 2,
        endAyah: 32,
        service: service(adapter),
      );
      addTearDown(bloc.close);
      await bloc.load();
      await bloc.next();
      expect(bloc.state.error, isTrue);
      expect(bloc.state.pageNumber, 2);
      fail = false;
      await bloc.load();
      expect(bloc.state.error, isFalse);
      expect(
        [bloc.state.pageNumber, bloc.state.from, bloc.state.to],
        [3, 6, 20],
      );
    },
  );
  test('individual ayah includes selected translation in request', () async {
    final adapter = Adapter((_) => ok(ayah(255)));
    final result = await service(adapter).loadAyah(2, 255, translation: 161);
    expect(adapter.requests.single.path, '/quran/ayahs/2/255');
    expect(adapter.requests.single.queryParameters['translations'], 161);
    expect(result.ayahNumber, 255);
  });
}
