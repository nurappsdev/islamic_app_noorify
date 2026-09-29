import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/datasources/quran_playlist_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/repositories/quran_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_playlist_store.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_playlist.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_playlist_repository.dart';

class QuranPlaylistRepositoryImpl implements QuranPlaylistRepository {
  QuranPlaylistRepositoryImpl(
    this._remote, {
    bool Function()? isSignedIn,
    this.cacheFor = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _isSignedIn = isSignedIn ?? (() => AuthLocalDataSourceImpl().hasToken),
       _now = now ?? DateTime.now {
    _readingTrackedSub = QuranReadingRepositoryImpl.shared.onReadingTracked
        .listen((_) => _onReadingTracked());
  }

  static final QuranPlaylistRepositoryImpl shared =
      QuranPlaylistRepositoryImpl(QuranPlaylistRemoteDataSourceImpl());

  final QuranPlaylistRemoteDataSource _remote;
  final bool Function() _isSignedIn;
  final DateTime Function() _now;
  final Duration cacheFor;

  StreamSubscription<void>? _readingTrackedSub;
  final _cache = <String, ({DateTime at, QuranPlaylistsResponse value})>{};
  final _inFlight = <String, Future<QuranPlaylistsResponse>>{};
  final _detailsCache = <String, ({DateTime at, QuranPlaylist value})>{};
  final _detailsInFlight = <String, Future<QuranPlaylist>>{};
  final _ayahsCache =
      <String, ({DateTime at, PaginatedQuranPlaylistAyahs value})>{};
  final _ayahsInFlight = <String, Future<PaginatedQuranPlaylistAyahs>>{};
  final _playlistChanged = StreamController<void>.broadcast();
  int _generation = 0;

  @override
  bool get isSignedIn {
    try {
      return _isSignedIn();
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<void> get onPlaylistChanged => _playlistChanged.stream;

  void _onReadingTracked() {
    invalidateCache();
    _playlistChanged.add(null);
  }

  @override
  void invalidateCache() {
    _generation++;
    _cache.clear();
    _inFlight.clear();
    _detailsCache.clear();
    _detailsInFlight.clear();
    _ayahsCache.clear();
    _ayahsInFlight.clear();
  }

  @override
  Future<Either<Failure, QuranPlaylist>> createPlaylist(
    CreateQuranPlaylistRequest request,
  ) async {
    final result = await _guard(() => _remote.createPlaylist(request));
    if (result.isRight()) {
      invalidateCache();
      _playlistChanged.add(null);
    }
    return result;
  }

  @override
  Future<Either<Failure, QuranPlaylistsResponse>> getPlaylists({
    String? searchTerm,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final key = '${searchTerm ?? ""}:$page:$limit';
    if (!forceRefresh) {
      final hit = _cache[key];
      if (hit != null && _now().difference(hit.at) < cacheFor) {
        return Right(hit.value);
      }
    }

    final generation = _generation;
    final request = _inFlight[key] ??= _remote
        .getPlaylists(searchTerm: searchTerm, page: page, limit: limit)
        .whenComplete(() {
          if (generation == _generation) _inFlight.remove(key);
        });

    final result = await _guard(() async => await request);
    return result.fold(
      (failure) async {
        // Fallback to local store for initial render or when offline
        if (page == 1 && (searchTerm == null || searchTerm.isEmpty)) {
          final localPlaylists = await QuranPlaylistStore.loadPlaylists();
          if (localPlaylists.isNotEmpty) {
            return Right(
              QuranPlaylistsResponse(
                playlists: localPlaylists,
                meta: QuranPlaylistMeta(
                  page: 1,
                  limit: localPlaylists.length,
                  total: localPlaylists.length,
                  totalPage: 1,
                ),
              ),
            );
          }
        }
        return Left(failure);
      },
      (response) {
        if (generation == _generation) {
          _cache[key] = (at: _now(), value: response);
          if (page == 1 && (searchTerm == null || searchTerm.isEmpty)) {
            // Keep local store warm as secondary cache
            QuranPlaylistStore.savePlaylists(response.playlists);
          }
        }
        return Right(response);
      },
    );
  }

  @override
  Future<Either<Failure, QuranPlaylist>> getPlaylistDetails(
    String playlistId, {
    bool forceRefresh = false,
  }) async {
    final key = playlistId;
    if (!forceRefresh) {
      final hit = _detailsCache[key];
      if (hit != null && _now().difference(hit.at) < cacheFor) {
        return Right(hit.value);
      }
    }

    final generation = _generation;
    final request = _detailsInFlight[key] ??= _remote
        .getPlaylistDetails(playlistId)
        .whenComplete(() {
          if (generation == _generation) _detailsInFlight.remove(key);
        });

    final result = await _guard(() async => await request);
    if (generation == _generation) {
      result.fold((_) {}, (playlist) {
        _detailsCache[key] = (at: _now(), value: playlist);
      });
    }
    return result;
  }

  @override
  Future<Either<Failure, QuranPlaylist>> updatePlaylist(
    String playlistId,
    UpdateQuranPlaylistRequest request,
  ) async {
    final result = await _guard(
      () => _remote.updatePlaylist(playlistId, request),
    );
    if (result.isRight()) {
      invalidateCache();
      _playlistChanged.add(null);
    }
    return result;
  }

  @override
  Future<Either<Failure, void>> deletePlaylist(String playlistId) async {
    final result = await _guard(() => _remote.deletePlaylist(playlistId));
    if (result.isRight()) {
      invalidateCache();
      _playlistChanged.add(null);
    }
    return result;
  }

  @override
  Future<Either<Failure, PaginatedQuranPlaylistAyahs>> getPlaylistAyahs(
    String playlistId, {
    String filter = 'all',
    bool withText = true,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final key = '$playlistId:$filter:$page:$limit';
    if (!forceRefresh) {
      final hit = _ayahsCache[key];
      if (hit != null && _now().difference(hit.at) < cacheFor) {
        return Right(hit.value);
      }
    }

    final generation = _generation;
    final request = _ayahsInFlight[key] ??= _remote
        .getPlaylistAyahs(
          playlistId,
          filter: filter,
          withText: withText,
          page: page,
          limit: limit,
        )
        .whenComplete(() {
          if (generation == _generation) _ayahsInFlight.remove(key);
        });

    final result = await _guard(() async => await request);
    if (generation == _generation) {
      result.fold((_) {}, (response) {
        _ayahsCache[key] = (at: _now(), value: response);
      });
    }
    return result;
  }

  @override
  Future<Either<Failure, void>> savePosition(
    String playlistId, {
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final result = await _guard(
      () => _remote.savePosition(
        playlistId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      ),
    );
    return result;
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (e, stack) {
      // Usually a response that no longer matches the model; keep it visible.
      debugPrint('QuranPlaylistRepository: $e\n$stack');
      return const Left(UnknownFailure());
    }
  }

  void dispose() {
    _readingTrackedSub?.cancel();
  }
}
