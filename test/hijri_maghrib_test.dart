import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/home/domain/calendar/date_labels.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

void main() {
  const maghrib = PrayerClockTime(hour: 18, minute: 0);

  for (final bangla in [false, true]) {
    group('hijriDateLabel (${bangla ? 'bangla' : 'english'})', () {
      final day = DateTime(2026, 9, 28);

      test('before Maghrib keeps the base date', () {
        expect(
          hijriDateLabel(
            day.add(const Duration(hours: 17, minutes: 59)),
            bangla: bangla,
            maghrib: maghrib,
          ),
          hijriDateLabel(day, bangla: bangla),
        );
      });

      test('from Maghrib on adds exactly one day', () {
        final next = hijriDateLabel(
          day.add(const Duration(days: 1)),
          bangla: bangla,
        );
        for (final t in [
          const Duration(hours: 18),
          const Duration(hours: 21),
          const Duration(hours: 23, minutes: 59),
        ]) {
          expect(
            hijriDateLabel(day.add(t), bangla: bangla, maghrib: maghrib),
            next,
          );
        }
      });

      test('midnight does not add a second day', () {
        final evening = hijriDateLabel(
          day.add(const Duration(hours: 20)),
          bangla: bangla,
          maghrib: maghrib,
        );
        final afterMidnight = hijriDateLabel(
          day.add(const Duration(days: 1, minutes: 30)),
          bangla: bangla,
          maghrib: maghrib,
        );
        expect(afterMidnight, evening);
      });

      test('rolls over months and years correctly', () {
        // The evening of any day equals the next day's daytime date, across
        // every Hijri month boundary in the range.
        for (var i = 0; i < 800; i++) {
          final d = DateTime(2025, 1, 1).add(Duration(days: i));
          expect(
            hijriDateLabel(
              d.add(const Duration(hours: 19)),
              bangla: bangla,
              maghrib: maghrib,
            ),
            hijriDateLabel(
              d.add(const Duration(days: 1, hours: 12)),
              bangla: bangla,
              maghrib: maghrib,
            ),
            reason: '$d',
          );
        }
      });
    });
  }

  test('without a Maghrib time the base date is shown', () {
    final late = DateTime(2026, 9, 28, 22);
    expect(hijriDateLabel(late), hijriDateLabel(DateTime(2026, 9, 28)));
  });

  group('local Bangladesh date', () {
    // 28 Sep 2026 is 17 Rabi' al-thani in the Saudi calendar, but 16 locally.
    final day = DateTime(2026, 9, 28);

    test('shows the 16th during the day', () {
      final noon = day.add(const Duration(hours: 12));
      expect(
        hijriDateLabel(noon, maghrib: maghrib),
        "16 Rabi' al-thani 1448 Hijri",
      );
      expect(
        hijriDateLabel(noon, bangla: true, maghrib: maghrib),
        '১৬ রবিউস সানি ১৪৪৮ হিজরি',
      );
    });

    test('changes to the 17th only after Maghrib', () {
      final evening = day.add(const Duration(hours: 19));
      expect(
        hijriDateLabel(evening, maghrib: maghrib),
        "17 Rabi' al-thani 1448 Hijri",
      );
      expect(
        hijriDateLabel(evening, bangla: true, maghrib: maghrib),
        '১৭ রবিউস সানি ১৪৪৮ হিজরি',
      );
    });

    test('stays on the 17th through midnight until the next Maghrib', () {
      for (final t in [
        const Duration(days: 1, minutes: 5),
        const Duration(days: 1, hours: 12),
        const Duration(days: 1, hours: 17, minutes: 59),
      ]) {
        expect(
          hijriDateLabel(day.add(t), maghrib: maghrib),
          "17 Rabi' al-thani 1448 Hijri",
        );
      }
    });
  });
}
