import 'package:tuhfatul_muslim/features/quran/domain/quran_playlist.dart';

sealed class QuranPlaylistEvent {
  const QuranPlaylistEvent();
}

/// Loads the user's Quran playlists.
class LoadQuranPlaylists extends QuranPlaylistEvent {
  const LoadQuranPlaylists({this.forceRefresh = false, this.searchTerm});

  final bool forceRefresh;
  final String? searchTerm;
}

/// Loads the next page of playlists.
class LoadMoreQuranPlaylists extends QuranPlaylistEvent {
  const LoadMoreQuranPlaylists();
}

/// Loads details of a specific playlist.
class LoadQuranPlaylistDetails extends QuranPlaylistEvent {
  const LoadQuranPlaylistDetails({
    required this.playlistId,
    this.forceRefresh = false,
  });

  final String playlistId;
  final bool forceRefresh;
}

/// Submits a request to create a new Quran playlist.
class CreateQuranPlaylistSubmitted extends QuranPlaylistEvent {
  const CreateQuranPlaylistSubmitted(this.request);

  final CreateQuranPlaylistRequest request;
}

/// Submits a request to update an existing Quran playlist.
class UpdateQuranPlaylistSubmitted extends QuranPlaylistEvent {
  const UpdateQuranPlaylistSubmitted({
    required this.playlistId,
    required this.request,
  });

  final String playlistId;
  final UpdateQuranPlaylistRequest request;
}

/// Submits a request to delete a Quran playlist.
class DeleteQuranPlaylist extends QuranPlaylistEvent {
  const DeleteQuranPlaylist({required this.playlistId});

  final String playlistId;
}

/// Loads ayahs for a playlist.
class LoadPlaylistAyahs extends QuranPlaylistEvent {
  const LoadPlaylistAyahs({
    required this.playlistId,
    this.filter = 'all',
    this.withText = true,
    this.page = 1,
    this.limit = 20,
    this.forceRefresh = false,
  });

  final String playlistId;
  final String filter;
  final bool withText;
  final int page;
  final int limit;
  final bool forceRefresh;
}

/// Loads the next page of ayahs for a playlist.
class LoadMorePlaylistAyahs extends QuranPlaylistEvent {
  const LoadMorePlaylistAyahs({required this.playlistId});

  final String playlistId;
}

/// Changes the ayahs filter ('all', 'read', 'unread').
class ChangePlaylistAyahsFilter extends QuranPlaylistEvent {
  const ChangePlaylistAyahsFilter({
    required this.playlistId,
    required this.filter,
  });

  final String playlistId;
  final String filter;
}

/// Saves the user's resume position in the playlist.
class SavePlaylistPosition extends QuranPlaylistEvent {
  const SavePlaylistPosition({
    required this.playlistId,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final String playlistId;
  final int surahNumber;
  final int ayahNumber;
}

/// Clears operation result flags (createSuccess, updateSuccess, deleteSuccess).
class ClearPlaylistOperations extends QuranPlaylistEvent {
  const ClearPlaylistOperations();
}
