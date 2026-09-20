enum EbookDownloadStatus { checking, idle, downloading, downloaded, failed }

class EbookDownloadState {
  const EbookDownloadState({
    this.status = EbookDownloadStatus.checking,
    this.progress,
    this.filePath,
  });

  final EbookDownloadStatus status;

  /// 0..1 while downloading; null when the total size isn't known.
  final double? progress;

  /// Where the PDF is saved, once [EbookDownloadStatus.downloaded].
  final String? filePath;
}
