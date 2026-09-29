import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_playlist.dart';

abstract interface class QuranPlaylistRepository {
  /// Whether a user is currently signed in.
  bool get isSignedIn;

  /// Emits whenever a playlist is created, updated, deleted, or reading is tracked.
  Stream<void> get onPlaylistChanged;

  /// Creates a new Quran playlist on the server.
  Future<Either<Failure, QuranPlaylist>> createPlaylist(
    CreateQuranPlaylistRequest request,
  );

  /// Retrieves user's Quran playlists with pagination and optional search.
  Future<Either<Failure, QuranPlaylistsResponse>> getPlaylists({
    String? searchTerm,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  });

  /// Retrieves detailed information for a specific playlist.
  Future<Either<Failure, QuranPlaylist>> getPlaylistDetails(
    String playlistId, {
    bool forceRefresh = false,
  });

  /// Updates an existing Quran playlist.
  Future<Either<Failure, QuranPlaylist>> updatePlaylist(
    String playlistId,
    UpdateQuranPlaylistRequest request,
  );

  /// Deletes a Quran playlist.
  Future<Either<Failure, void>> deletePlaylist(String playlistId);

  /// Retrieves paginated list of ayahs for a playlist with read status.
  Future<Either<Failure, PaginatedQuranPlaylistAyahs>> getPlaylistAyahs(
    String playlistId, {
    String filter = 'all',
    bool withText = true,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  });

  /// Saves the user's resume position in the playlist.
  Future<Either<Failure, void>> savePosition(
    String playlistId, {
    required int surahNumber,
    required int ayahNumber,
  });

  /// Invalidates cached playlists and details in memory.
  void invalidateCache();
}
