import 'package:bloc/bloc.dart';

import 'language_event.dart';
import 'language_preference.dart';
import 'language_state.dart';

export 'language_event.dart';
export 'language_preference.dart';
export 'language_state.dart';

/// The app language. It starts as [initialLanguage] - the saved choice, loaded
/// before the first frame so nothing renders in the wrong language - and every
/// change is saved so it is still there after a restart.
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc({
    AppLanguage initialLanguage = LanguagePreference.defaultLanguage,
    Future<void> Function(AppLanguage language)? persist,
  }) : _persist = persist ?? LanguagePreference.save,
       super(LanguageState(language: initialLanguage)) {
    on<UpdateLanguage>((event, emit) async {
      if (state.language == event.language) return;
      // Switch the screen first; saving is slower and must not delay it.
      emit(state.copyWith(language: event.language));
      try {
        await _persist(event.language);
      } catch (_) {
        // The language still changes for this session if it can't be saved.
      }
    });
  }

  final Future<void> Function(AppLanguage language) _persist;
}
