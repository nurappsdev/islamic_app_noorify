/// Tracks the work that must finish before the opening splash can choose its
/// next route.  Keeping this separate from the first Flutter frame lets the
/// native Android launch screen hand off immediately instead of waiting for
/// Firebase, audio, alarm, and local-storage setup.
class AppStartup {
  AppStartup._();

  static Future<void> _ready = Future<void>.value();

  static Future<void> get ready => _ready;

  static void begin(Future<void> initialization) {
    _ready = initialization;
  }
}
