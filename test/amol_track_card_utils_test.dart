import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/home/presentation/utils/amol_track_card_utils.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_state.dart';

void main() {
  group('truncateWords', () {
    test('keeps short titles unchanged', () {
      expect(truncateWords('Complete Daily Amol', 15), 'Complete Daily Amol');
    });

    test('truncates long titles by word count', () {
      const title =
          'Complete all daily morning and evening Islamic activities and track your progress every day with care';
      expect(
        truncateWords(title, 15),
        'Complete all daily morning and evening Islamic activities and track your progress every day with...',
      );
    });
  });

  group('localizedShortMonthYear', () {
    test('uses the first three English characters', () {
      expect(
        localizedShortMonthYear(DateTime(2026, 9), AppLanguage.english),
        'Sep 2026',
      );
      expect(
        localizedShortMonthYear(DateTime(2026, 1), AppLanguage.english),
        'Jan 2026',
      );
    });

    test('uses the active Bengali month name and digits', () {
      expect(
        localizedShortMonthYear(DateTime(2026, 9), AppLanguage.bangla),
        'সেপ্ট ২০২৬',
      );
      expect(
        localizedShortMonthYear(DateTime(2026, 1), AppLanguage.bangla),
        'জানু ২০২৬',
      );
      expect(
        localizedShortMonthYear(DateTime(2026, 6), AppLanguage.bangla),
        'জুন ২০২৬',
      );
    });
  });

  test('uses profile name first and handles missing names', () {
    expect(
      resolveAmolTrackUserName(
        profileName: '  Rajib Ahmed  ',
        dashboardName: 'Guest User',
      ),
      'Rajib Ahmed',
    );
    expect(
      resolveAmolTrackUserName(profileName: ' ', dashboardName: 'Guest User'),
      'Guest User',
    );
    expect(resolveAmolTrackUserName(), isEmpty);
  });
}
