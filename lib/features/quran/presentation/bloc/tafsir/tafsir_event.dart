abstract class TafsirEvent {
  const TafsirEvent();
}

class LoadTafsir extends TafsirEvent {
  const LoadTafsir(this.verseKey);

  final String verseKey;
}
