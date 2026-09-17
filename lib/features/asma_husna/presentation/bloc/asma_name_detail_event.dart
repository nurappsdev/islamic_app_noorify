abstract class AsmaNameDetailEvent {
  const AsmaNameDetailEvent();
}

/// Fetches the full explanation for [id]. Fired once when the detail screen
/// opens.
class LoadAsmaNameDetail extends AsmaNameDetailEvent {
  const LoadAsmaNameDetail(this.id);

  final String id;
}
