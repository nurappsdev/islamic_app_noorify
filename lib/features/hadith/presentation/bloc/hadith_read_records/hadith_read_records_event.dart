abstract class HadithReadRecordsEvent {
  const HadithReadRecordsEvent();
}

/// Loads (or reloads) the first page; also the retry after a failure.
class LoadHadithReadRecords extends HadithReadRecordsEvent {
  const LoadHadithReadRecords();
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithReadRecords extends HadithReadRecordsEvent {
  const LoadMoreHadithReadRecords();
}
