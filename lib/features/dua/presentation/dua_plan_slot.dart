import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// The five `slot` values `POST /duas/planner/plans` accepts, in display
/// order (`anytime` first — the API's own default).
const List<String> duaPlanSlots = [
  'anytime',
  'morning',
  'afternoon',
  'evening',
  'night',
];

/// [slot]'s label in the app's language, falling back to "Anytime" for an
/// unrecognized value.
String duaSlotLabel(AppText appText, String slot) => switch (slot) {
  'morning' => appText.duaSlotMorning,
  'afternoon' => appText.duaSlotAfternoon,
  'evening' => appText.duaSlotEvening,
  'night' => appText.duaSlotNight,
  _ => appText.duaSlotAnytime,
};
