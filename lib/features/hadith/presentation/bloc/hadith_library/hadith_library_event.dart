abstract class HadithLibraryEvent {
  const HadithLibraryEvent();
}

class LoadHadithLibrary extends HadithLibraryEvent {
  const LoadHadithLibrary({this.refresh = false});

  /// Pull-to-refresh: fetch the shelf from the API instead of answering
  /// from the device's stored copy.
  final bool refresh;
}
