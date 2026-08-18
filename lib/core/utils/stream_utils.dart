import 'dart:async';

/// A broadcast stream that emits [value] and closes, for every listener.
///
/// `Stream.value` is single-subscription: when a StreamBuilder's element is
/// recycled (e.g. a scrolled list sliver remounts) and re-subscribes to the
/// same instance, it throws "Bad state: Stream has already been listened to".
/// Firestore's `snapshots()` is broadcast, so the signed-out/guest fallbacks
/// returned in its place must be broadcast too.
Stream<T> broadcastValueStream<T>(T value) {
  return Stream<T>.multi((controller) {
    controller
      ..add(value)
      ..close();
  }, isBroadcast: true);
}
