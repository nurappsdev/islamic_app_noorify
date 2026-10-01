abstract class HadithLastReadEvent {
  const HadithLastReadEvent();
}

/// Fetches the last-read hadith. The current value stays on screen while a
/// reload is in flight, so returning from reading doesn't flash a loader.
class LoadHadithLastRead extends HadithLastReadEvent {
  const LoadHadithLastRead();
}
