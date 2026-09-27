abstract class HomeDashboardEvent {
  const HomeDashboardEvent();
}

/// Loads `GET /home/dashboard`. A no-op (stays on the fallback content)
/// when there is no signed-in session.
///
/// With [silent], the data already on screen stays put while the refetch runs
/// (no loading state), and a failed refetch keeps it too.
class LoadHomeDashboard extends HomeDashboardEvent {
  const LoadHomeDashboard({this.silent = false});

  final bool silent;
}
