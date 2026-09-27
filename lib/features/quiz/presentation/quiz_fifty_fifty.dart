import 'dart:math';

/// Picks the option keys the 50/50 lifeline hides, leaving two on screen.
///
/// The server withholds the answer key while a quiz is played, so the keys
/// are chosen at random; the option already checked, if any, is never hidden.
Set<String> pickFiftyFiftyRemovals(
  List<String> optionKeys, {
  String? keep,
  Random? random,
}) {
  final removeCount = optionKeys.length - 2;
  if (removeCount <= 0) return const {};
  final candidates = optionKeys.where((key) => key != keep).toList()
    ..shuffle(random);
  return candidates.take(removeCount).toSet();
}
