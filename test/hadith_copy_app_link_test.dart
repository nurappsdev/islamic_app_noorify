import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_share_link.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// What the readers build for a hadith read in Bangla.
const _citation = 'হাদিস নং: ১ — চল্লিশ হাদিস (আন-নববী)\nতথ্যসূত্র: বুখারী: ১';
const _invitation = 'তুহফাতুল মুসলিম অ্যাপে আরও হাদিস পড়ুন:';

/// A copied part as it reaches the clipboard: the part, its citation, then
/// the invitation and the link — the composition both readers use.
String _copied(String part) =>
    withAppLink([part, _citation].join('\n\n'), _invitation);

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

  group('hadithCitation', () {
    test('the hadith number, its book and its reference', () {
      expect(
        hadithCitation(
          numberLabel: 'হাদিস নং',
          number: '১',
          book: 'চল্লিশ হাদিস (আন-নববী)',
          referenceLine: 'তথ্যসূত্র: বুখারী: ১',
        ),
        _citation,
      );
    });

    // A hadith with no reference text, or read outside a named book, still
    // has to say which hadith it is.
    test('what is missing is left out', () {
      expect(
        hadithCitation(numberLabel: 'Hadith No', number: '7', book: 'Forty'),
        'Hadith No: 7 — Forty',
      );
      expect(
        hadithCitation(
          numberLabel: 'Hadith No',
          number: '7',
          referenceLine: 'Reference: Muslim 1907',
        ),
        'Hadith No: 7\nReference: Muslim 1907',
      );
      expect(
        hadithCitation(numberLabel: 'Hadith No', number: '7'),
        'Hadith No: 7',
      );
    });
  });

  // What the person on the other end of the paste receives.
  group('a copied part', () {
    test('the translation on its own carries the reference and link', () {
      expect(
        _copied('নিশ্চয় সকল কাজ নিয়তের উপর নির্ভরশীল।'),
        'নিশ্চয় সকল কাজ নিয়তের উপর নির্ভরশীল।\n'
        '\n'
        'হাদিস নং: ১ — চল্লিশ হাদিস (আন-নববী)\n'
        'তথ্যসূত্র: বুখারী: ১\n'
        '\n'
        '$_invitation\n'
        '\n'
        '$tuhfatulMuslimPlayStoreUrl',
      );
    });

    test('the Arabic on its own carries them too', () {
      final message = _copied('إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ');

      expect(message, startsWith('إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ'));
      expect(message, contains('হাদিস নং: ১ — চল্লিশ হাদিস (আন-নববী)'));
      expect(message, contains('তথ্যসূত্র: বুখারী: ১'));
      expect(message, endsWith(tuhfatulMuslimPlayStoreUrl));
    });

    // The reference used to sit inside the whole-hadith text; it is in the
    // citation now, so it must appear once, not twice.
    test('the whole hadith carries each line once', () {
      final whole = [
        '১. সকল কাজ নিয়তের উপর নির্ভরশীল',
        'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
        'নিশ্চয় সকল কাজ নিয়তের উপর নির্ভরশীল।',
      ].join('\n\n');
      final message = _copied(whole);

      expect('তথ্যসূত্র:'.allMatches(message), hasLength(1));
      expect('হাদিস নং:'.allMatches(message), hasLength(1));
      expect(tuhfatulMuslimPlayStoreUrl.allMatches(message), hasLength(1));
    });
  });

  group('the invitation line', () {
    test('reads in both languages', () {
      expect(
        AppText.forLanguage(AppLanguage.bangla).hadithShareInvitation,
        _invitation,
      );
      expect(
        AppText.forLanguage(AppLanguage.english).hadithShareInvitation,
        'Read more hadith with Tuhfatul Muslim:',
      );
    });

    test('the hadith-number label reads in both languages', () {
      expect(AppText.forLanguage(AppLanguage.bangla).hadithNoLabel, 'হাদিস নং');
      expect(
        AppText.forLanguage(AppLanguage.english).hadithNoLabel,
        'Hadith No',
      );
    });
  });
}
