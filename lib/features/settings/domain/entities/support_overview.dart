/// The support contact details shown on the Admin Support screen, as
/// returned by `GET /settings/overview`.
class SupportOverview {
  const SupportOverview({
    this.hotline,
    this.email,
    this.supportEmail,
    this.appVersion,
  });

  final String? hotline;
  final String? email;
  final String? supportEmail;
  final String? appVersion;

  /// The address to write to: the dedicated support mailbox when the API
  /// sends one, otherwise the general one.
  String? get contactEmail {
    final support = supportEmail?.trim();
    if (support != null && support.isNotEmpty) return support;
    final general = email?.trim();
    return (general != null && general.isNotEmpty) ? general : null;
  }

  bool get isEmpty => (hotline?.trim().isEmpty ?? true) && contactEmail == null;
}
