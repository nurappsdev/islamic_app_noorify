import 'package:tuhfatul_muslim/features/settings/domain/entities/support_overview.dart';

/// Reads `GET /settings/overview`' `data`:
/// ```json
/// {
///   "hotline": "(609) 327-7992",
///   "email": "abc@gmail.com",
///   "supportEmail": "support@tuhfatulmuslim.app",
///   "appVersion": "1.1.0"
/// }
/// ```
class SupportOverviewModel extends SupportOverview {
  const SupportOverviewModel({
    super.hotline,
    super.email,
    super.supportEmail,
    super.appVersion,
  });

  factory SupportOverviewModel.fromJson(Map<String, dynamic> json) {
    return SupportOverviewModel(
      hotline: _text(json['hotline']) ?? _text(json['phone']),
      email: _text(json['email']),
      supportEmail: _text(json['supportEmail']),
      appVersion: _text(json['appVersion']) ?? _text(json['version']),
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
