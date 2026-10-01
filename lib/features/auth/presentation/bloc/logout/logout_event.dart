abstract class LogoutEvent {
  const LogoutEvent();
}

/// Fired when the user taps "Sign Out" on the Profile screen.
class LogoutRequested extends LogoutEvent {
  const LogoutRequested();
}
