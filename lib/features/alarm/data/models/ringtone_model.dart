import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';

class RingtoneModel extends Ringtone {
  const RingtoneModel({
    required super.id,
    required super.name,
    required super.duration,
    required super.audioUrl,
  });

  factory RingtoneModel.fromJson(Map<String, dynamic> json) => RingtoneModel(
    id: json['id'] as String,
    name: json['name'] as String,
    duration: json['duration'] as String? ?? '',
    audioUrl: json['audioUrl'] as String? ?? '',
  );
}
