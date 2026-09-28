import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/localization/localized_date_formatter.dart';
import 'package:islami_app_noorify/core/localization/localized_failure_message.dart';
import 'package:islami_app_noorify/core/localization/localized_number_formatter.dart';
import 'package:islami_app_noorify/core/localization/localized_time_formatter.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

const _en = AppLanguage.english;
const _bn = AppLanguage.bangla;

/// Any ASCII digit.
final _asciiDigit = RegExp('[0-9]');

void main() {
  tearDown(
    () => LanguagePreference.current = LanguagePreference.defaultLanguage,
  );

  group('LocalizedNumberFormatter', () {
    test('writes Bangla digits in Bangla and leaves English alone', () {
      const digits = '0123456789';
      expect(const LocalizedNumberFormatter(_bn).digits(digits), '০১২৩৪৫৬৭৮৯');
      expect(const LocalizedNumberFormatter(_en).digits(digits), digits);
    });

    test('converts only digits, so words, colons and dots stay', () {
      expect(
        const LocalizedNumberFormatter(_bn).digits('Point : 72.25/1120 pts'),
        'Point : ৭২.২৫/১১২০ pts',
      );
    });

    test('integer and decimal', () {
      const bn = LocalizedNumberFormatter(_bn);
      expect(bn.integer(1120), '১১২০');
      expect(bn.decimal(72.25), '৭২.২৫');
      expect(bn.decimal(40.0), '৪০');
      expect(const LocalizedNumberFormatter(_en).decimal(72.5), '72.5');
    });
  });

  group('LocalizedTimeFormatter', () {
    const evening = PrayerClockTime(hour: 17, minute: 56);

    test('English keeps digits and AM/PM', () {
      expect(const LocalizedTimeFormatter(_en).clock(evening), '5:56 PM');
    });

    test('Bangla has Bangla digits and পূর্বাহ্ণ / অপরাহ্ণ', () {
      const bn = LocalizedTimeFormatter(_bn);
      expect(bn.clock(evening), '৫:৫৬ অপরাহ্ণ');
      expect(
        bn.clock(const PrayerClockTime(hour: 0, minute: 5)),
        '১২:০৫ পূর্বাহ্ণ',
      );
      expect(
        bn.clock(const PrayerClockTime(hour: 12, minute: 0)),
        '১২:০০ অপরাহ্ণ',
      );
    });

    test(
      'ranges, already-formatted text and durations follow the language',
      () {
        const bn = LocalizedTimeFormatter(_bn);
        expect(
          bn.range(
            const PrayerClockTime(hour: 4, minute: 23),
            const PrayerClockTime(hour: 5, minute: 40),
          ),
          '৪:২৩ পূর্বাহ্ণ – ৫:৪০ পূর্বাহ্ণ',
        );
        expect(
          bn.localize('4:23 AM - 5:40 AM'),
          '৪:২৩ পূর্বাহ্ণ - ৫:৪০ পূর্বাহ্ণ',
        );
        expect(bn.localize('--:--'), '--:--');
        expect(
          const LocalizedTimeFormatter(_en).duration(hours: 2, minutes: 5),
          '2 hr 5 min',
        );
        expect(bn.duration(hours: 2, minutes: 5), '২ ঘণ্টা ৫ মিনিট');
      },
    );

    test('no ASCII digit or AM/PM survives in Bangla', () {
      for (var minute = 0; minute < 24 * 60; minute += 37) {
        final text = const LocalizedTimeFormatter(
          _bn,
        ).clock(PrayerClockTime(hour: minute ~/ 60, minute: minute % 60));
        expect(text, isNot(matches(_asciiDigit)), reason: text);
        expect(text, isNot(contains('AM')), reason: text);
        expect(text, isNot(contains('PM')), reason: text);
      }
    });
  });

  group('LocalizedDateFormatter', () {
    // 28 Sep 2026, midday: 16 Rabi' al-thani 1448 locally, 13 Ashwin 1433.
    final noon = DateTime(2026, 9, 28, 12);

    test('Hijri date follows the language, with no mixed-language pieces', () {
      expect(
        const LocalizedDateFormatter(_en).hijri(noon),
        "16 Rabi' al-thani 1448 Hijri",
      );
      expect(
        const LocalizedDateFormatter(_bn).hijri(noon),
        '১৬ রবিউস সানি ১৪৪৮ হিজরি',
      );
      expect(
        const LocalizedDateFormatter(_bn).hijri(noon, withSuffix: false),
        '১৬ রবিউস সানি ১৪৪৮',
      );
    });

    test('Hijri day turns over at Maghrib in both languages', () {
      const maghrib = PrayerClockTime(hour: 17, minute: 49);
      final evening = DateTime(2026, 9, 28, 19);
      expect(
        const LocalizedDateFormatter(_en).hijri(evening, maghrib: maghrib),
        "17 Rabi' al-thani 1448 Hijri",
      );
      expect(
        const LocalizedDateFormatter(_bn).hijri(evening, maghrib: maghrib),
        '১৭ রবিউস সানি ১৪৪৮ হিজরি',
      );
    });

    test('Bengali calendar date', () {
      expect(
        const LocalizedDateFormatter(_en).banglaCalendar(noon),
        '13 Ashwin, 1433',
      );
      expect(
        const LocalizedDateFormatter(_bn).banglaCalendar(noon),
        '১৩ আশ্বিন ১৪৩৩',
      );
    });

    test('Gregorian date, with the weekday, in both languages', () {
      final en = const LocalizedDateFormatter(_en);
      final bn = const LocalizedDateFormatter(_bn);
      expect(en.gregorian(noon), '28 September 2026');
      expect(en.gregorian(noon, shortMonth: true), '28 Sep 2026');
      expect(
        en.gregorian(noon, withWeekday: true),
        'Monday, 28 September 2026',
      );
      expect(bn.gregorian(noon), '২৮ সেপ্টেম্বর ২০২৬');
      expect(bn.gregorian(noon, shortMonth: true), '২৮ সেপ্টেম্বর ২০২৬');
      expect(
        bn.gregorian(noon, withWeekday: true),
        'সোমবার, ২৮ সেপ্টেম্বর ২০২৬',
      );
    });

    test('short weekday names, counted from Sunday', () {
      const en = LocalizedDateFormatter(_en);
      const bn = LocalizedDateFormatter(_bn);
      expect(
        [for (var i = 0; i < 7; i++) en.weekdayShort(i)],
        ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      );
      expect(bn.weekdayShort(0), 'রবি');
      expect(bn.weekdayShort(6), 'শনি');
    });

    test('a Bangla date never contains an ASCII digit or a Latin letter', () {
      const bn = LocalizedDateFormatter(_bn);
      for (var d = 0; d < 400; d += 7) {
        final date = DateTime(2026, 1, 1).add(Duration(days: d));
        for (final text in [
          bn.hijri(date),
          bn.banglaCalendar(date),
          bn.gregorian(date, withWeekday: true),
        ]) {
          expect(text, isNot(matches(_asciiDigit)), reason: text);
          expect(text, isNot(matches(RegExp('[A-Za-z]'))), reason: text);
        }
      }
    });
  });

  group('failure messages', () {
    test('client-made messages follow the selected language', () {
      LanguagePreference.current = _en;
      expect(
        localizeFailureMessage('The request timed out. Please try again.'),
        AppText.forLanguage(_en).failureTimeout,
      );
      LanguagePreference.current = _bn;
      expect(
        localizeFailureMessage('The request timed out. Please try again.'),
        'অনুরোধের সময় শেষ হয়ে গেছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      );
      expect(
        localizeFailureMessage('No internet connection.'),
        'ইন্টারনেট সংযোগ নেই। অনুগ্রহ করে আবার চেষ্টা করুন।',
      );
    });

    test('a status code gets Bangla digits, and the message is not mixed', () {
      LanguagePreference.current = _bn;
      expect(
        localizeFailureMessage('Request failed (404).'),
        'অনুরোধ ব্যর্থ হয়েছে (৪০৪)।',
      );
      expect(
        localizeFailureMessage('Request failed (network error).'),
        AppText.forLanguage(_bn).failureNetwork,
      );
    });

    test('domain validation messages and parse errors are localized', () {
      LanguagePreference.current = _bn;
      expect(
        localizeFailureMessage('Please enter a valid email address.'),
        'সঠিক ইমেইল ঠিকানা লিখুন',
      );
      expect(
        localizeFailureMessage('Profile response is missing "data".'),
        AppText.forLanguage(_bn).failureUnexpectedResponse,
      );
      expect(
        localizeFailureMessage(
          'Password must be at least 8 characters and include an uppercase '
          'letter, a number and a special character.',
        ),
        contains('৮'),
      );
    });

    test("the server's own text is left exactly as the server wrote it", () {
      LanguagePreference.current = _bn;
      expect(
        localizeFailureMessage('Invalid or expired access token.'),
        'Invalid or expired access token.',
      );
    });
  });
}
