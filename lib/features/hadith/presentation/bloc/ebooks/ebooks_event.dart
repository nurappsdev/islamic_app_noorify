abstract class EbooksEvent {
  const EbooksEvent();
}

class LoadEbooks extends EbooksEvent {
  const LoadEbooks({this.refresh = false});

  /// See [LoadHadithLibrary.refresh].
  final bool refresh;
}
