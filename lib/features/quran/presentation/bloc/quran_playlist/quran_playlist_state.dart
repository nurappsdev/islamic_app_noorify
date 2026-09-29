import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_playlist.dart';

enum QuranPlaylistLoadStatus { initial, loading, success, failure }

class QuranPlaylistState {
  const QuranPlaylistState({
    this.status = QuranPlaylistLoadStatus.initial,
    this.failure,
    this.playlists = const [],
    this.meta = const QuranPlaylistMeta(),
    this.isPaginating = false,
    this.searchTerm,
    this.isLoadingDetails = false,
    this.detailsFailure,
    this.selectedPlaylistDetails,
    this.isCreating = false,
    this.createSuccess = false,
    this.createFailure,
    this.createdPlaylist,
    this.isUpdating = false,
    this.updateSuccess = false,
    this.updateFailure,
    this.isDeleting = false,
    this.deleteSuccess = false,
    this.deleteFailure,
    this.isLoadingAyahs = false,
    this.isPaginatingAyahs = false,
    this.ayahsFailure,
    this.ayahs = const [],
    this.ayahsMeta = const QuranPlaylistMeta(),
    this.ayahsFilter = 'all',
  });

  // Playlists list
  final QuranPlaylistLoadStatus status;
  final Failure? failure;
  final List<QuranPlaylist> playlists;
  final QuranPlaylistMeta meta;
  final bool isPaginating;
  final String? searchTerm;

  // Selected playlist details
  final bool isLoadingDetails;
  final Failure? detailsFailure;
  final QuranPlaylist? selectedPlaylistDetails;

  // Create
  final bool isCreating;
  final bool createSuccess;
  final Failure? createFailure;
  final QuranPlaylist? createdPlaylist;

  // Update
  final bool isUpdating;
  final bool updateSuccess;
  final Failure? updateFailure;

  // Delete
  final bool isDeleting;
  final bool deleteSuccess;
  final Failure? deleteFailure;

  // Ayahs
  final bool isLoadingAyahs;
  final bool isPaginatingAyahs;
  final Failure? ayahsFailure;
  final List<QuranPlaylistAyah> ayahs;
  final QuranPlaylistMeta ayahsMeta;
  final String ayahsFilter;

  bool get hasMore => meta.hasMore;
  bool get hasMoreAyahs => ayahsMeta.hasMore;

  QuranPlaylistState copyWith({
    QuranPlaylistLoadStatus? status,
    Failure? failure,
    bool clearFailure = false,
    List<QuranPlaylist>? playlists,
    QuranPlaylistMeta? meta,
    bool? isPaginating,
    String? searchTerm,
    bool? isLoadingDetails,
    Failure? detailsFailure,
    bool clearDetailsFailure = false,
    QuranPlaylist? selectedPlaylistDetails,
    bool? isCreating,
    bool? createSuccess,
    Failure? createFailure,
    bool clearCreateFailure = false,
    QuranPlaylist? createdPlaylist,
    bool? isUpdating,
    bool? updateSuccess,
    Failure? updateFailure,
    bool clearUpdateFailure = false,
    bool? isDeleting,
    bool? deleteSuccess,
    Failure? deleteFailure,
    bool clearDeleteFailure = false,
    bool? isLoadingAyahs,
    bool? isPaginatingAyahs,
    Failure? ayahsFailure,
    bool clearAyahsFailure = false,
    List<QuranPlaylistAyah>? ayahs,
    QuranPlaylistMeta? ayahsMeta,
    String? ayahsFilter,
  }) => QuranPlaylistState(
    status: status ?? this.status,
    failure: clearFailure ? null : (failure ?? this.failure),
    playlists: playlists ?? this.playlists,
    meta: meta ?? this.meta,
    isPaginating: isPaginating ?? this.isPaginating,
    searchTerm: searchTerm ?? this.searchTerm,
    isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
    detailsFailure:
        clearDetailsFailure ? null : (detailsFailure ?? this.detailsFailure),
    selectedPlaylistDetails:
        selectedPlaylistDetails ?? this.selectedPlaylistDetails,
    isCreating: isCreating ?? this.isCreating,
    createSuccess: createSuccess ?? this.createSuccess,
    createFailure:
        clearCreateFailure ? null : (createFailure ?? this.createFailure),
    createdPlaylist: createdPlaylist ?? this.createdPlaylist,
    isUpdating: isUpdating ?? this.isUpdating,
    updateSuccess: updateSuccess ?? this.updateSuccess,
    updateFailure:
        clearUpdateFailure ? null : (updateFailure ?? this.updateFailure),
    isDeleting: isDeleting ?? this.isDeleting,
    deleteSuccess: deleteSuccess ?? this.deleteSuccess,
    deleteFailure:
        clearDeleteFailure ? null : (deleteFailure ?? this.deleteFailure),
    isLoadingAyahs: isLoadingAyahs ?? this.isLoadingAyahs,
    isPaginatingAyahs: isPaginatingAyahs ?? this.isPaginatingAyahs,
    ayahsFailure:
        clearAyahsFailure ? null : (ayahsFailure ?? this.ayahsFailure),
    ayahs: ayahs ?? this.ayahs,
    ayahsMeta: ayahsMeta ?? this.ayahsMeta,
    ayahsFilter: ayahsFilter ?? this.ayahsFilter,
  );
}
