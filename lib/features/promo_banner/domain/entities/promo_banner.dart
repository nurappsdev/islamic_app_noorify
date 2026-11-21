/// What a tap on a banner should do, as the admin configured it.
enum PromoBannerAction {
  /// Go to a screen inside the app. [PromoBanner.actionUrl] is a path.
  appScreen,

  /// Open [PromoBanner.actionUrl] outside the app.
  externalUrl,

  /// Show the image and nothing else.
  none;

  /// The server's spelling (`app_screen`, `url`, `none`). Anything else is
  /// read as [none]: a banner whose action we do not understand is still a
  /// perfectly good picture, and guessing could send someone anywhere.
  static PromoBannerAction fromJson(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'app_screen' || 'appscreen' || 'screen' => appScreen,
        'url' || 'external' || 'web' => externalUrl,
        _ => none,
      };
}

/// One entry of `GET /promo-banners/active`.
class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.action,
    required this.actionUrl,
    this.displayOrder = 0,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final PromoBannerAction action;

  /// `/duas` for [PromoBannerAction.appScreen], a full URL for
  /// [PromoBannerAction.externalUrl], and empty for [PromoBannerAction.none].
  final String actionUrl;

  final int displayOrder;

  /// Only a banner with an image is worth a slide — the whole card is the
  /// picture, so one without it would render as an empty box.
  bool get isDisplayable => imageUrl.trim().isNotEmpty;
}
