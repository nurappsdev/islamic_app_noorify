import 'app_preferences_state.dart';

abstract class AppPreferencesEvent {
  const AppPreferencesEvent();
}

class UpdateFontSize extends AppPreferencesEvent {
  const UpdateFontSize(this.size);

  final AppFontSize size;
}

class ToggleDarkTheme extends AppPreferencesEvent {
  const ToggleDarkTheme();
}

class UpdateDarkThemeEnabled extends AppPreferencesEvent {
  const UpdateDarkThemeEnabled(this.enabled);

  final bool enabled;
}
