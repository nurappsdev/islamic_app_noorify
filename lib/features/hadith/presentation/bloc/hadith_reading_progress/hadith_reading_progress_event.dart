abstract class HadithReadingProgressEvent {
  const HadithReadingProgressEvent();
}

/// First load: shows the loading state.
class LoadHadithReadingProgress extends HadithReadingProgressEvent {
  const LoadHadithReadingProgress();
}

/// Re-fetches after the user came back from reading. Keeps the current
/// values on screen until the fresh ones arrive.
class RefreshHadithReadingProgress extends HadithReadingProgressEvent {
  const RefreshHadithReadingProgress();
}
