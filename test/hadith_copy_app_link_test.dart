import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_share_link.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

void main() {
  group('withAppLink', () {
    test('puts the invitation and the Play Store link under the text', () {
      final message = withAppLink('হাদিস ১', 'আরও পড়ুন:');

      expect(message, 'হাদিস ১\n\nআরও পড়ুন:\n\n$tuhfatulMuslimPlayStoreUrl');
      expect(message, startsWith('হাদিস ১'), reason: 'the hadith comes first');
      expect(message, endsWith(tuhfatulMuslimPlayStoreUrl));
    });

    test('the link is the app on Google Play', () {
      expect(
        tuhfatulMuslimPlayStoreUrl,
        'https://play.google.com/store/apps/details'
        '?id=com.tuhfatulmuslim.app&pcampaignid=web_share',
      );
    });

    // Copying nothing must not put a bare advert on the clipboard.
    test('empty text stays empty', () {
      expect(withAppLink('', 'আরও পড়ুন:'), isEmpty);
      expect(withAppLink('   \n ', 'আরও পড়ুন:'), isEmpty);
    });

    test('without an invitation the link still follows the text', () {
      expect(
        withAppLink('হাদিস ১', ''),
        'হাদিস ১\n\n$tuhfatulMuslimPlayStoreUrl',
      );
    });

    test('the text is trimmed, so there is one blank line before it', () {
      expect(
        withAppLink('হাদিস ১\n\n', 'আরও পড়ুন:'),
        'হাদিস ১\n\nআরও পড়ুন:\n\n$tuhfatulMuslimPlayStoreUrl',
      );
    });
  });

  group('the invitation line', () {
    test('reads in both languages', () {
      expect(
        AppText.forLanguage(AppLanguage.bangla).hadithShareInvitation,
        'তুহফাতুল মুসলিম অ্যাপে আরও হাদিস পড়ুন:',
      );
      expect(
        AppText.forLanguage(AppLanguage.english).hadithShareInvitation,
        'Read more hadith with Tuhfatul Muslim:',
      );
    });
  });
}
