enum SurahAudioDownloadStatus {
  idle,
  checking,
  downloading,
  complete,
  failed,
}

class SurahAudioDownloadState {
  const SurahAudioDownloadState({
    this.status = SurahAudioDownloadStatus.idle,
    this.done = 0,
    this.total = 0,
    this.errorMessage,
  });

  final SurahAudioDownloadStatus status;
  final int done;
  final int total;
  final String? errorMessage;

  bool get isBusy =>
      status == SurahAudioDownloadStatus.downloading ||
      status == SurahAudioDownloadStatus.checking;

  double? get progress =>
      total > 0 ? (done / total).clamp(0.0, 1.0) : null;

  SurahAudioDownloadState copyWith({
    SurahAudioDownloadStatus? status,
    int? done,
    int? total,
    String? errorMessage,
  }) {
    return SurahAudioDownloadState(
      status: status ?? this.status,
      done: done ?? this.done,
      total: total ?? this.total,
      errorMessage: errorMessage,
    );
  }
}
