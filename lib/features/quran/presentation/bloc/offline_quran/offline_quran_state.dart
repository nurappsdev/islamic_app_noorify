enum OfflineQuranStatus {
  /// Looking on disk for an existing build.
  checking,

  /// Not built yet — show the setup prompt.
  needsSetup,

  /// Building the local database from the bundled Quran file.
  preparing,

  /// Database is on the device and ready to read.
  ready,

  /// Setup attempt failed.
  failed,
}

class OfflineQuranState {
  const OfflineQuranState({
    this.status = OfflineQuranStatus.checking,
    this.done = 0,
    this.total = 0,
    this.errorMessage,
  });

  final OfflineQuranStatus status;

  /// Units completed in the current step (ayahs written, mostly).
  final int done;
  final int total;
  final String? errorMessage;

  /// Setup completion in 0..1, or null while the total is unknown.
  double? get progress => total > 0 ? (done / total).clamp(0.0, 1.0) : null;

  OfflineQuranState copyWith({
    OfflineQuranStatus? status,
    int? done,
    int? total,
    String? errorMessage,
  }) {
    return OfflineQuranState(
      status: status ?? this.status,
      done: done ?? this.done,
      total: total ?? this.total,
      errorMessage: errorMessage,
    );
  }
}
