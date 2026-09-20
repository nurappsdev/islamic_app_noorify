import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_event.dart';
import 'app_preferences_state.dart';

export 'app_preferences_event.dart';
export 'app_preferences_state.dart';

class AppPreferencesBloc
    extends Bloc<AppPreferencesEvent, AppPreferencesState> {
  /// Shared-preferences key holding whether dark mode is on.
  static const darkThemeKey = 'app_dark_theme_enabled';

  /// [darkThemeEnabled] is the saved choice, read before `runApp` so the
  /// first frame already uses the right theme.
  AppPreferencesBloc({bool darkThemeEnabled = false})
    : super(AppPreferencesState(darkThemeEnabled: darkThemeEnabled)) {
    on<UpdateFontSize>((event, emit) {
      if (state.fontSize == event.size) return;
      emit(state.copyWith(fontSize: event.size));
    });

    on<ToggleDarkTheme>((event, emit) {
      emit(state.copyWith(darkThemeEnabled: !state.darkThemeEnabled));
      _saveDarkTheme(state.darkThemeEnabled);
    });

    on<UpdateDarkThemeEnabled>((event, emit) {
      if (state.darkThemeEnabled == event.enabled) return;
      emit(state.copyWith(darkThemeEnabled: event.enabled));
      _saveDarkTheme(event.enabled);
    });
  }

  Future<void> _saveDarkTheme(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(darkThemeKey, enabled);
    } catch (_) {
      // Not persisted (e.g. no storage); the choice still applies this run.
    }
  }
}
