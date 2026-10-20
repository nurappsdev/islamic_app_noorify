abstract class DuaSettingsEvent {
  const DuaSettingsEvent();
}

class LoadDuaSettings extends DuaSettingsEvent {
  const LoadDuaSettings();
}

class SetDuaArabicFontSize extends DuaSettingsEvent {
  const SetDuaArabicFontSize(this.size);
  final double size;
}

class SetDuaTranslationFontSize extends DuaSettingsEvent {
  const SetDuaTranslationFontSize(this.size);
  final double size;
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

class ToggleDuaNarration extends DuaSettingsEvent {
  const ToggleDuaNarration(this.show);
  final bool show;
}

class ToggleDuaReference extends DuaSettingsEvent {
  const ToggleDuaReference(this.show);
  final bool show;
}
