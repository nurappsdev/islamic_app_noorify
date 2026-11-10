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

/// Both reading sizes at once — what a pinch on the reader commits when it
/// ends. One event, so the sizes it reached arrive together and neither
/// text is drawn at its old size while the other has moved.
class SetDuaFontSizes extends DuaSettingsEvent {
  const SetDuaFontSizes({required this.arabic, required this.translation});
  final double arabic;
  final double translation;
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
