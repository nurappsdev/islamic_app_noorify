class TafsirState {
  const TafsirState({
    this.isLoading = true,
    this.text = '',
    this.hasError = false,
  });

  final bool isLoading;
  final String text;
  final bool hasError;

  TafsirState copyWith({bool? isLoading, String? text, bool? hasError}) {
    return TafsirState(
      isLoading: isLoading ?? this.isLoading,
      text: text ?? this.text,
      hasError: hasError ?? this.hasError,
    );
  }
}
