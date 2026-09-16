import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';

enum AsmaHusnaStatus { initial, loading, success, failure }

class AsmaHusnaState {
  const AsmaHusnaState({
    this.status = AsmaHusnaStatus.initial,
    this.names = const [],
    this.query = '',
    this.failure,
    this.playingId,
    this.isBuffering = false,
  });

  final AsmaHusnaStatus status;
  final List<AsmaName> names;
  final String query;
  final Failure? failure;

  /// `_id` of the name whose audio is currently loading/playing.
  final String? playingId;
  final bool isBuffering;

  List<AsmaName> get filteredNames => query.trim().isEmpty
      ? names
      : names.where((n) => n.matches(query)).toList();

  AsmaHusnaState copyWith({
    AsmaHusnaStatus? status,
    List<AsmaName>? names,
    String? query,
    Failure? failure,
    bool clearFailure = false,
    String? playingId,
    bool clearPlayingId = false,
    bool? isBuffering,
  }) {
    return AsmaHusnaState(
      status: status ?? this.status,
      names: names ?? this.names,
      query: query ?? this.query,
      failure: clearFailure ? null : (failure ?? this.failure),
      playingId: clearPlayingId ? null : (playingId ?? this.playingId),
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }
}
