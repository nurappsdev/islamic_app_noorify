/// One entry in the alarm ringtone catalog (`GET /alarms/ringtones`).
class Ringtone {
  const Ringtone({
    required this.id,
    required this.name,
    required this.duration,
    required this.audioUrl,
  });

  final String id;
  final String name;
  final String duration;
  final String audioUrl;
}
