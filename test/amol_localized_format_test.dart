import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_entry.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_entry_label.dart';
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

  group('entry amounts', () {
    AmolEntry minutes(num amount) => AmolEntry(
      unit: 'minutes',
      entrySize: 5,
      entryPoints: 1,
      maxEntries: 9,
      entries: (amount ~/ 5).clamp(0, 9),
      amount: amount,
      targetAmount: 45,
    );

    test('writes the minutes tracked today in both languages', () {
      expect(
        formatAmolEntryAmount(
          minutes(25),
          AppText.forLanguage(AppLanguage.english),
          AppLanguage.english,
        ),
        '25 min',
      );
      expect(
        formatAmolEntryAmount(
          minutes(25),
          AppText.forLanguage(AppLanguage.bangla),
          AppLanguage.bangla,
        ),
        '২৫ মিনিট',
      );
    });

    test('past an hour it reads hours and minutes', () {
      expect(
        formatAmolEntryAmount(
          minutes(97),
          AppText.forLanguage(AppLanguage.english),
          AppLanguage.english,
        ),
        '1 hr 37 min',
      );
    });

    test('a counted unit keeps the name the API sends for it', () {
      expect(
        formatAmolEntryAmount(
          const AmolEntry(
            unit: 'count',
            entrySize: 100,
            entryPoints: 0.4,
            maxEntries: 1,
            entries: 3,
            amount: 300,
            targetAmount: 300,
            unitLabel: LocalizedText(en: 'zikr', bn: 'জিকির'),
          ),
          AppText.forLanguage(AppLanguage.bangla),
          AppLanguage.bangla,
        ),
        '৩০০ জিকির',
      );
    });
  });
}
