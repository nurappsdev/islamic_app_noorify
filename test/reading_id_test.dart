import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_reading_repository.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_reading_repository.dart';

/// These ids are generated the moment a reading bloc is constructed, so a
/// throw here takes down the whole screen. The ceiling used to be `1 << 32`,
/// which is 0 on Web (shifts of 32+ bits use 32-bit JS semantics there) and
/// made `Random.nextInt` throw a RangeError while building the surah list.
void main() {
  for (final (name, generate) in [
    ('newQuranReadingId', newQuranReadingId),
    ('newDuaReadingId', newDuaReadingId),
  ]) {
    group(name, () {
      test('generates an id without throwing, on every platform', () {
        expect(generate, returnsNormally);
        expect(generate(), isNotEmpty);
      });

      test('has both halves: a timestamp and a random suffix', () {
        final parts = generate().split('-');
        expect(parts, hasLength(2));
        // Base-36 digits only; an empty suffix would mean a zero ceiling.
        expect(parts[0], matches(RegExp(r'^[0-9a-z]+$')));
        expect(parts[1], matches(RegExp(r'^[0-9a-z]+$')));
      });

      test('does not repeat across many calls in the same microsecond', () {
        final ids = {for (var i = 0; i < 1000; i++) generate()};
        expect(ids, hasLength(1000));
      });
    });
  }
}
