import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_fifty_fifty.dart';

void main() {
  group('pickFiftyFiftyRemovals', () {
    test('hides all but two options, never the kept one', () {
      for (var seed = 0; seed < 50; seed++) {
        final removed = pickFiftyFiftyRemovals(
          ['A', 'B', 'C', 'D'],
          keep: 'C',
          random: Random(seed),
        );
        expect(removed, hasLength(2));
        expect(removed, isNot(contains('C')));
      }
    });

    test('hides nothing when two or fewer options remain', () {
      expect(pickFiftyFiftyRemovals(['A', 'B']), isEmpty);
      expect(pickFiftyFiftyRemovals(['A']), isEmpty);
    });

    test('keeps two of three or five options', () {
      expect(pickFiftyFiftyRemovals(['A', 'B', 'C']), hasLength(1));
      expect(pickFiftyFiftyRemovals(['A', 'B', 'C', 'D', 'E']), hasLength(3));
    });
  });
}
