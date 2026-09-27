import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/home/data/models/home_dashboard_model.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_state.dart';

void main() {
  test('keeps the dashboard API localized strings for both languages', () {
    final dashboard = HomeDashboardModel.fromJson({
      'userSummary': {
        'fullName': 'Guest User',
        'greetingText': 'Assalamu-Alaikum Wa-Rahmatullah',
        'localized': {
          'fullName': {'bn': 'অতিথি', 'en': 'Guest User'},
          'greetingText': {
            'bn': 'আসসালামু আলাইকুম ওয়া রাহমাতুল্লাহ',
            'en': 'Assalamu-Alaikum Wa-Rahmatullah',
          },
        },
      },
      'topHighlightCards': [
        {
          'id': 'card_1',
          'type': 'todays_amol',
          'title': 'My Amol Track',
          'pointsText': 'Point : 0/40',
          'percentage': 0,
          'localized': {
            'title': {'bn': 'আমার আমল', 'en': 'My Amol Track'},
            'pointsText': {'bn': 'পয়েন্ট : ০/৪০', 'en': 'Point : 0/40'},
            'percentage': {'value': 0, 'bn': '০', 'en': '0'},
          },
        },
      ],
      'pillarCards': [
        {
          'pillarKey': 'quran',
          'title': 'Quran',
          'points': 0,
          'maxPoints': 11,
          'percentage': 0,
          'formattedSubtext': '0 Min',
          'localized': {
            'title': {'bn': 'কুরআন', 'en': 'Quran'},
            'points': {'value': 0, 'bn': '০', 'en': '0'},
            'maxPoints': {'value': 11, 'bn': '১১', 'en': '11'},
            'formattedSubtext': {'bn': '০ মিনিট', 'en': '0 Min'},
          },
        },
      ],
    });

    expect(
      dashboard.userSummary.localizedFullName.resolve(AppLanguage.bangla),
      'অতিথি',
    );
    expect(
      dashboard.topHighlightCards.single.localizedPointsText.resolve(
        AppLanguage.bangla,
      ),
      'পয়েন্ট : ০/৪০',
    );
    expect(
      dashboard.pillarCards.single.localizedMaxPoints.resolve(
        AppLanguage.bangla,
      ),
      '১১',
    );
    expect(
      dashboard.pillarCards.single.localizedFormattedSubtext.resolve(
        AppLanguage.english,
      ),
      '0 Min',
    );
  });
}
