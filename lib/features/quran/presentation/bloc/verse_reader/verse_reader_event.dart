abstract class VerseReaderEvent {
  const VerseReaderEvent();
}

class LoadJuzVerses extends VerseReaderEvent {
  const LoadJuzVerses(this.juzNumber);

  final int juzNumber;
}
