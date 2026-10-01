import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_playlist.dart';

abstract interface class QuranPlaylistRemoteDataSource {
  /// `POST /quran/playlists`: creates a new Quran playlist.
  Future<QuranPlaylist> createPlaylist(CreateQuranPlaylistRequest request);

  /// `GET /quran/playlists?searchTerm={searchTerm}&page={page}&limit={limit}`:
  /// retrieves user's Quran playlists.
  Future<QuranPlaylistsResponse> getPlaylists({
    String? searchTerm,
    int page = 1,
    int limit = 10,
  });

  /// `GET /quran/playlists/{id}`: retrieves details of a specific playlist.
  Future<QuranPlaylist> getPlaylistDetails(String playlistId);

  /// `PATCH /quran/playlists/{id}`: updates a Quran playlist.
  Future<QuranPlaylist> updatePlaylist(
    String playlistId,
    UpdateQuranPlaylistRequest request,
  );

  /// `DELETE /quran/playlists/{id}`: deletes a Quran playlist.
  Future<void> deletePlaylist(String playlistId);

  /// `GET /quran/playlists/{id}/ayahs?filter={filter}&withText={withText}&page={page}&limit={limit}`:
  /// retrieves paginated list of ayahs in the playlist.
  Future<PaginatedQuranPlaylistAyahs> getPlaylistAyahs(
    String playlistId, {
    String filter = 'all',
    bool withText = true,
    int page = 1,
    int limit = 20,
  });

  /// `PATCH /quran/playlists/{id}/position`: saves the user's resume position in the playlist.
  Future<void> savePosition(
    String playlistId, {
    required int surahNumber,
    required int ayahNumber,
  });
}

class QuranPlaylistRemoteDataSourceImpl
    implements QuranPlaylistRemoteDataSource {
  QuranPlaylistRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dioOverride = dio,
      _localOverride = local;

  final Dio? _dioOverride;
  final AuthLocalDataSource? _localOverride;

  late final Dio _dio = _dioOverride ?? DioClient().dio;
  late final AuthLocalDataSource _local =
      _localOverride ?? AuthLocalDataSourceImpl();

  @override
  Future<QuranPlaylist> createPlaylist(
    CreateQuranPlaylistRequest request,
  ) async {
    final data = await _sendAuthed(
      'POST',
      ApiConstants.quranPlaylistsEndPoint,
      data: request.toJson(),
      what: 'Create Quran playlist',
    );
    if (data is! Map<String, dynamic>) {
      throw ParsingException(
        'Create Quran playlist response is missing "data".',
      );
    }
    return QuranPlaylist.fromJson(data);
  }

  @override
  Future<QuranPlaylistsResponse> getPlaylists({
    String? searchTerm,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _getEnvelope(ApiConstants.quranPlaylistsEndPoint, {
      if (searchTerm != null && searchTerm.isNotEmpty)
        'searchTerm': searchTerm,
      'page': page,
      'limit': limit,
    }, 'Quran playlists');
    return QuranPlaylistsResponse.fromJson(json);
  }

  @override
  Future<QuranPlaylist> getPlaylistDetails(String playlistId) async {
    final data = await _sendAuthed(
      'GET',
      ApiConstants.quranPlaylistEndPoint(playlistId),
      what: 'Get Quran playlist details',
    );
    if (data is! Map<String, dynamic>) {
      throw ParsingException(
        'Get Quran playlist details response is missing "data".',
      );
    }
    return QuranPlaylist.fromJson(data);
  }

  @override
  Future<QuranPlaylist> updatePlaylist(
    String playlistId,
    UpdateQuranPlaylistRequest request,
  ) async {
    final data = await _sendAuthed(
      'PATCH',
      ApiConstants.quranPlaylistEndPoint(playlistId),
      data: request.toJson(),
      what: 'Update Quran playlist',
    );
    if (data is! Map<String, dynamic>) {
      throw ParsingException(
        'Update Quran playlist response is missing "data".',
      );
    }
    return QuranPlaylist.fromJson(data);
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _sendAuthed(
      'DELETE',
      ApiConstants.quranPlaylistEndPoint(playlistId),
      what: 'Delete Quran playlist',
    );
  }

  @override
  Future<PaginatedQuranPlaylistAyahs> getPlaylistAyahs(
    String playlistId, {
    String filter = 'all',
    bool withText = true,
    int page = 1,
    int limit = 20,
  }) async {
    final json = await _getEnvelope(
      ApiConstants.quranPlaylistAyahsEndPoint(playlistId),
      {
        'filter': filter,
        'withText': withText,
        'page': page,
        'limit': limit,
      },
      'Quran playlist ayahs',
    );
    return PaginatedQuranPlaylistAyahs.fromJson(json);
  }

  @override
  Future<void> savePosition(
    String playlistId, {
    required int surahNumber,
    required int ayahNumber,
  }) async {
    await _sendAuthed(
      'PATCH',
      ApiConstants.quranPlaylistPositionEndPoint(playlistId),
      data: {'surahNumber': surahNumber, 'ayahNumber': ayahNumber},
      what: 'Save Quran playlist position',
    );
  }

  Future<dynamic> _sendAuthed(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    required String what,
  }) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final raw = response.data;
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
    return json['data'];
  }

  Future<Map<String, dynamic>> _getEnvelope(
    String path,
    Map<String, dynamic> query,
    String what,
  ) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final raw = response.data;
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
    return json;
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badCertificate:
        return NetworkException('Could not establish a secure connection.');
      case DioExceptionType.cancel:
        return NetworkException('The request was cancelled.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final data = e.response?.data;
        final json = data is Map<String, dynamic>
            ? data
            : const <String, dynamic>{};
        return ServerException(
          _extractError(json) ??
              'Request failed (${e.response?.statusCode ?? 'network error'}).',
          statusCode: e.response?.statusCode,
        );
    }
  }

  String? _extractError(Map<String, dynamic> json) {
    final sources = json['errorSources'];
    if (sources is List && sources.isNotEmpty) {
      final messages = sources
          .whereType<Map>()
          .map((e) => e['message']?.toString())
          .where((m) => m != null && m.isNotEmpty)
          .join('\n');
      if (messages.isNotEmpty) return messages;
    }
    final message = json['message']?.toString();
    return (message != null && message.isNotEmpty) ? message : null;
  }
}
