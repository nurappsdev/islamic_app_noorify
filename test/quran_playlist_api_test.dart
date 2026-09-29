import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/localization/localized_failure_message.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/quran/data/datasources/quran_playlist_remote_data_source.dart';
import 'package:islami_app_noorify/features/quran/data/repositories/quran_playlist_repository_impl.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_playlist.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_playlist/quran_playlist_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.status = 200});

  Object body;
  int status;
  final requests = <RequestOptions>[];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeLocal implements AuthLocalDataSource {
  _FakeLocal(this.token);

  final String? token;

  @override
  String? getToken() => token;

  @override
  bool get hasToken => token != null;

  @override
  Future<void> cacheToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

final _samplePlaylistJson = {
  "_id": "pl_101",
  "userId": "user_42",
  "name": "Daily Tilawat",
  "description": "My daily morning recitation",
  "reciterId": "mishary_alafasy",
  "items": [
    {
      "_id": "item_1",
      "type": "surah",
      "surahNumber": 1,
      "fromAyah": 1,
      "toAyah": 7,
      "title": "Al-Fatihah",
      "surahNameEnglish": "Al-Fatihah",
      "surahNameBangla": "আল-ফাতিহা",
      "surahNameArabic": "الفاتحة",
      "revelationPlace": "Meccan",
      "totalAyahs": 7,
      "readAyahs": 7,
      "remainingAyahs": 0,
      "percentage": 100.0,
      "isCompleted": true,
      "start": 1,
      "end": 7,
    },
    {
      "_id": "item_2",
      "type": "ayahs",
      "surahNumber": 2,
      "fromAyah": 1,
      "toAyah": 5,
      "title": "Al-Baqarah",
      "surahNameEnglish": "Al-Baqarah",
      "surahNameBangla": "আল-বাকারা",
      "surahNameArabic": "البقرة",
      "revelationPlace": "Medinian",
      "totalAyahs": 5,
      "readAyahs": 2,
      "remainingAyahs": 3,
      "percentage": 40.0,
      "isCompleted": false,
      "start": 1,
      "end": 5,
    },
  ],
  "counts": {
    "totalItems": 2,
    "totalAyahs": 12,
    "completedAyahs": 9,
    "remainingAyahs": 3,
    "percentage": 75.0,
    "isCompleted": false,
  },
  "nextAyah": {
    "surahNumber": 2,
    "ayahNumber": 3,
    "ayahKey": "2:3",
    "paraNumber": 1,
    "surahNameEnglish": "Al-Baqarah",
    "surahNameBangla": "আল-বাকারা",
    "surahNameArabic": "البقرة",
  },
  "resumeFrom": {
    "surahNumber": 2,
    "ayahNumber": 3,
  },
  "isActive": true,
  "createdAt": "2026-09-29T10:00:00.000Z",
  "updatedAt": "2026-09-29T10:30:00.000Z",
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Quran Playlist Domain Model', () {
    test('parses server playlist JSON correctly and preserves compatibility', () {
      final playlist = QuranPlaylist.fromJson(_samplePlaylistJson);

      expect(playlist.id, 'pl_101');
      expect(playlist.name, 'Daily Tilawat');
      expect(playlist.title, 'Daily Tilawat'); // alias
      expect(playlist.description, 'My daily morning recitation');
      expect(playlist.reciterId, 'mishary_alafasy');
      expect(playlist.items.length, 2);

      // Counts
      expect(playlist.counts.totalAyahs, 12);
      expect(playlist.counts.completedAyahs, 9);
      expect(playlist.counts.remainingAyahs, 3);
      expect(playlist.counts.percentage, 75.0);
      expect(playlist.counts.isCompleted, false);

      // Helper getters
      expect(playlist.totalAyahs, 12);
      expect(playlist.completedAyahs, 9);
      expect(playlist.remainingAyahs, 3);
      expect(playlist.percentage, 75.0);
      expect(playlist.isCompleted, false);

      // Next Ayah
      expect(playlist.nextAyah, isNotNull);
      expect(playlist.nextAyah!.surahNumber, 2);
      expect(playlist.nextAyah!.ayahNumber, 3);
      expect(playlist.nextAyah!.surahNameEnglish, 'Al-Baqarah');

      // First item
      final item1 = playlist.items[0];
      expect(item1.id, 'item_1');
      expect(item1.surahNumber, 1);
      expect(item1.surahNo, 1); // alias
      expect(item1.surahName, 'Al-Fatihah'); // alias
      expect(item1.arabicName, 'الفاتحة'); // alias
      expect(item1.fromAyah, 1);
      expect(item1.startAyah, 1); // alias
      expect(item1.toAyah, 7);
      expect(item1.endAyah, 7); // alias
      expect(item1.totalAyah, 7); // alias
      expect(item1.isCompleted, true);

      // Second item
      final item2 = playlist.items[1];
      expect(item2.id, 'item_2');
      expect(item2.surahNo, 2);
      expect(item2.startAyah, 1);
      expect(item2.endAyah, 5);
      expect(item2.readAyahs, 2);
      expect(item2.remainingAyahs, 3);
      expect(item2.percentage, 40.0);
      expect(item2.isCompleted, false);
    });

    test('backward compatibility: handles local store format without crashing', () {
      final localJson = {
        'id': 'local_1',
        'title': 'Local Playlist',
        'items': [
          {
            'surahNo': 36,
            'surahName': 'Ya-Sin',
            'arabicName': 'يس',
            'revelationPlace': 'Meccan',
            'startAyah': 1,
            'endAyah': 12,
            'totalAyah': 83,
          }
        ],
        'createdAt': '2026-09-29T08:00:00.000Z',
      };

      final playlist = QuranPlaylist.fromJson(localJson);
      expect(playlist.id, 'local_1');
      expect(playlist.name, 'Local Playlist');
      expect(playlist.title, 'Local Playlist');
      expect(playlist.items.length, 1);
      expect(playlist.items.first.surahNo, 36);
      expect(playlist.items.first.surahName, 'Ya-Sin');
      expect(playlist.items.first.arabicName, 'يس');
      expect(playlist.items.first.startAyah, 1);
      expect(playlist.items.first.endAyah, 12);
    });
  });

  group('QuranPlaylistRemoteDataSource', () {
    test('getPlaylists sends correct auth header and query params', () async {
      final stub = _StubAdapter({
        'statusCode': 200,
        'success': true,
        'message': 'Playlists retrieved',
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPage': 1},
        'data': [_samplePlaylistJson],
      });
      final dio = Dio()..httpClientAdapter = stub;
      final ds = QuranPlaylistRemoteDataSourceImpl(
        dio: dio,
        local: _FakeLocal('token_xyz'),
      );

      final response = await ds.getPlaylists(page: 1, limit: 10);
      expect(response.playlists.length, 1);
      expect(response.playlists.first.name, 'Daily Tilawat');
      expect(stub.last.headers['Authorization'], 'Bearer token_xyz');
      expect(stub.last.queryParameters['page'], 1);
      expect(stub.last.queryParameters['limit'], 10);
    });

    test('createPlaylist sends POST and parses returned playlist', () async {
      final stub = _StubAdapter({
        'statusCode': 201,
        'success': true,
        'message': 'Created',
        'data': _samplePlaylistJson,
      });
      final dio = Dio()..httpClientAdapter = stub;
      final ds = QuranPlaylistRemoteDataSourceImpl(
        dio: dio,
        local: _FakeLocal('token_xyz'),
      );

      final request = CreateQuranPlaylistRequest(
        name: 'Daily Tilawat',
        description: 'My daily morning recitation',
        items: const [
          PlaylistItemInput(type: 'surah', surahNumber: 1),
        ],
      );

      final created = await ds.createPlaylist(request);
      expect(created.id, 'pl_101');
      expect(created.name, 'Daily Tilawat');
      expect(stub.last.method, 'POST');
    });

    test('maps 409 conflict server response correctly', () async {
      final stub = _StubAdapter(
        {
          'statusCode': 409,
          'success': false,
          'message': 'You already have a playlist with this name.',
        },
        status: 409,
      );
      final dio = Dio()..httpClientAdapter = stub;
      final ds = QuranPlaylistRemoteDataSourceImpl(
        dio: dio,
        local: _FakeLocal('token_xyz'),
      );

      expect(
        () => ds.createPlaylist(const CreateQuranPlaylistRequest(name: 'Duplicate')),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'status', 409)),
      );
    });
  });

  group('QuranPlaylistRepositoryImpl', () {
    test('deduplicates in-flight calls and caches getPlaylists', () async {
      final stub = _StubAdapter({
        'statusCode': 200,
        'success': true,
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPage': 1},
        'data': [_samplePlaylistJson],
      });
      final dio = Dio()..httpClientAdapter = stub;
      final ds = QuranPlaylistRemoteDataSourceImpl(
        dio: dio,
        local: _FakeLocal('token_xyz'),
      );

      final repo = QuranPlaylistRepositoryImpl(
        ds,
        isSignedIn: () => true,
        cacheFor: const Duration(minutes: 5),
      );

      // Concurrent calls
      final res1Future = repo.getPlaylists();
      final res2Future = repo.getPlaylists();

      final res1 = await res1Future;
      final res2 = await res2Future;

      expect(res1.isRight(), isTrue);
      expect(res2.isRight(), isTrue);
      // Only 1 HTTP call should have been made
      expect(stub.requests.length, 1);
    });

    test('createPlaylist invalidates cache and triggers onPlaylistChanged', () async {
      final stub = _StubAdapter({
        'statusCode': 200,
        'success': true,
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPage': 1},
        'data': [_samplePlaylistJson],
      });
      final dio = Dio()..httpClientAdapter = stub;
      final ds = QuranPlaylistRemoteDataSourceImpl(
        dio: dio,
        local: _FakeLocal('token_xyz'),
      );

      final repo = QuranPlaylistRepositoryImpl(ds, isSignedIn: () => true);
      bool changedEmitted = false;
      repo.onPlaylistChanged.listen((_) => changedEmitted = true);

      // First fetch caches
      await repo.getPlaylists();
      expect(stub.requests.length, 1);

      // Create playlist
      stub.body = {
        'statusCode': 201,
        'success': true,
        'data': _samplePlaylistJson,
      };
      await repo.createPlaylist(const CreateQuranPlaylistRequest(name: 'New Pl'));
      await Future<void>.delayed(Duration.zero);
      expect(changedEmitted, isTrue);

      // Second fetch must hit the network again (cache was invalidated)
      stub.body = {
        'statusCode': 200,
        'success': true,
        'meta': {'page': 1, 'limit': 10, 'total': 2, 'totalPage': 1},
        'data': [_samplePlaylistJson, _samplePlaylistJson],
      };
      await repo.getPlaylists();
      expect(stub.requests.length, 3); // 1 list + 1 create + 1 list
    });
  });

  group('QuranPlaylistBloc', () {
    test('LoadQuranPlaylists emits success state with playlists', () async {
      final stub = _StubAdapter({
        'statusCode': 200,
        'success': true,
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPage': 1},
        'data': [_samplePlaylistJson],
      });
      final dio = Dio()..httpClientAdapter = stub;
      final ds = QuranPlaylistRemoteDataSourceImpl(
        dio: dio,
        local: _FakeLocal('token_xyz'),
      );
      final repo = QuranPlaylistRepositoryImpl(ds, isSignedIn: () => true);
      final bloc = QuranPlaylistBloc(repository: repo);

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<QuranPlaylistState>()
              .having((s) => s.status, 'status', QuranPlaylistLoadStatus.loading),
          isA<QuranPlaylistState>()
              .having((s) => s.status, 'status', QuranPlaylistLoadStatus.success)
              .having((s) => s.playlists.length, 'length', 1)
              .having((s) => s.playlists.first.name, 'name', 'Daily Tilawat'),
        ]),
      );

      bloc.add(const LoadQuranPlaylists());
    });
  });

  group('Quran Playlist Localization', () {
    test('localizes duplicate playlist name in English and Bangla', () {
      LanguagePreference.current = AppLanguage.english;
      final enMessage =
          localizeFailureMessage('you already have a playlist with this name');
      expect(enMessage, 'You already have a Quran playlist with this name.');

      LanguagePreference.current = AppLanguage.bangla;
      final bnMessage =
          localizeFailureMessage('you already have a playlist with this name');
      expect(bnMessage, 'এই নামে আপনার ইতোমধ্যে একটি কুরআন প্লেলিস্ট রয়েছে।');
    });
  });
}
