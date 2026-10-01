abstract class DuaSettingsEvent {
  const DuaSettingsEvent();
}

class LoadDuaSettings extends DuaSettingsEvent {
  const LoadDuaSettings();
}

class SetDuaFontSize extends DuaSettingsEvent {
  const SetDuaFontSize(this.multiplier);
  final double multiplier;
}

class ToggleDuaArabic extends DuaSettingsEvent {
  const ToggleDuaArabic(this.show);
  final bool show;
}

class ToggleDuaTranslation extends DuaSettingsEvent {
  const ToggleDuaTranslation(this.show);
  final bool show;
}

class ToggleDuaTransliteration extends DuaSettingsEvent {
  const ToggleDuaTransliteration(this.show);
  final bool show;
}
