import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_localized_format.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

void main() {
  setUpAll(AppText.load);

  test('formats API point totals in the selected language', () {
    expect(
      formatAmolPoints(
        72.25,
        1120,
        AppText.forLanguage(AppLanguage.bangla),
        AppLanguage.bangla,
      ),
      'পয়েন্ট : ৭২.২৫/১১২০',
    );
    expect(
      formatAmolPoints(
        72.25,
        1120,
        AppText.forLanguage(AppLanguage.english),
        AppLanguage.english,
      ),
      'Point : 72.25/1120',
    );
  });

  test('uses local month names and digits for the resolved API range', () {
    expect(
      formatAmolRange(
        '2026-09-17',
        '2026-09-23',
        AppText.forLanguage(AppLanguage.bangla),
        AppLanguage.bangla,
      ),
      '১৭ সেপ্টেম্বর ২০২৬ - ২৩ সেপ্টেম্বর ২০২৬',
    );
  });
}
