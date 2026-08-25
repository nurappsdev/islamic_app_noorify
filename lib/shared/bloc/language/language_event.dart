import 'language_state.dart';

abstract class LanguageEvent {
  const LanguageEvent();
}

class UpdateLanguage extends LanguageEvent {
  const UpdateLanguage(this.language);

  final AppLanguage language;
}
