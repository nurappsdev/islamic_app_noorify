sealed class HadithBookEvent {
  const HadithBookEvent();
}

/// Check whether the book is already on the device.
class CheckHadithBook extends HadithBookEvent {
  const CheckHadithBook();
}

/// Parse the bundled source and write the book into the local database.
class DownloadHadithBook extends HadithBookEvent {
  const DownloadHadithBook();
}
