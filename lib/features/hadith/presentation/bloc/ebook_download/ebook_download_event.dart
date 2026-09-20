abstract class EbookDownloadEvent {
  const EbookDownloadEvent();
}

/// Looks for an already-downloaded copy when the screen opens.
class CheckEbookDownload extends EbookDownloadEvent {
  const CheckEbookDownload();
}

class StartEbookDownload extends EbookDownloadEvent {
  const StartEbookDownload();
}
