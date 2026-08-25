abstract class SurahDetailEvent {
  const SurahDetailEvent();
}

class LoadSurahDetail extends SurahDetailEvent {
  const LoadSurahDetail(this.surahNo);

  final int surahNo;
}
