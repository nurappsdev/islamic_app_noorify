abstract class AsmaHusnaEvent {
  const AsmaHusnaEvent();
}

/// Fetches all 99 names. Fired once when the bloc is created.
class LoadAsmaNames extends AsmaHusnaEvent {
  const LoadAsmaNames();
}

/// Filters the already-loaded names by transliteration / Arabic / Bangla
/// name / meaning as the user types in the search field.
class SearchAsmaNames extends AsmaHusnaEvent {
  const SearchAsmaNames(this.query);

  final String query;
}

/// Toggles audio playback for [nameId]/[audioUrl]: plays it, or pauses it if
/// it's already the one playing.
class TogglePlayAsmaAudio extends AsmaHusnaEvent {
  const TogglePlayAsmaAudio({required this.nameId, required this.audioUrl});

  final String nameId;
  final String audioUrl;
}
