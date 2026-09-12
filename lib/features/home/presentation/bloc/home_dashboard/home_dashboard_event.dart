abstract class HomeDashboardEvent {
  const HomeDashboardEvent();
}

/// Loads `GET /home/dashboard`. A no-op (stays on the fallback content)
/// when there is no signed-in session.
class LoadHomeDashboard extends HomeDashboardEvent {
  const LoadHomeDashboard();
}
