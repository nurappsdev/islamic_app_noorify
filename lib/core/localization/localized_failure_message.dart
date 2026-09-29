import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_preference.dart';

/// The user-facing text for a failure message, in the selected language.
///
/// The data layer creates its own messages in English (`No internet
/// connection.`, `Request failed (404).`, ...) and has no access to the
/// language. Those known client-made messages are translated here; anything
/// else - above all the server's own error text - is passed through untouched.
String localizeFailureMessage(String raw) {
  final text = AppText.forLanguage(LanguagePreference.current);
  final key = _normalize(raw);

  final known = <String, String>{
    'no internet connection': text.failureNetwork,
    'no internet connection. please try again': text.failureNetwork,
    'the request timed out. please try again': text.failureTimeout,
    'could not establish a secure connection': text.failureSecureConnection,
    'the request was cancelled': text.failureCancelled,
    'failed to read local storage': text.failureStorage,
    'something went wrong. please try again': text.failureUnknown,
    'received an unexpected response from the server':
        text.failureUnexpectedResponse,
    'failed to parse server response': text.failureUnexpectedResponse,
    'no signed in user found': text.failureNoSignedInUser,
    'this account does not use password sign-in': text.failureNoPasswordSignIn,
    'missing google id token': text.failureMissingGoogleToken,
    // Client-side checks that live in the domain layer.
    'please enter a valid email address': text.validatorEmailInvalid,
    'please enter your password': text.validatorPasswordEmpty,
    'please enter your full name': text.validatorNameShort,
    'enter the 6-digit code sent to your email': text.validatorOtpCode,
    'passwords do not match': text.validatorPasswordMismatch,
    'your reset session has expired. please request a new code':
        text.failureResetSessionExpired,
    'google sign-in is unavailable on this platform':
        text.failureGoogleUnavailable,
    'could not reach the audio server. check your connection':
        text.failureAudioServer,
    'no audio available for this surah': text.failureNoAudioSurah,
    'no audio available for this ayah': text.failureNoAudioAyah,
    'unable to load quran content': text.failureQuranContent,
    'could not load the surah list': text.failureSurahListLoad,
    'surah not found in offline database': text.failureNotAvailableOffline,
    'unknown juz': text.failureNotAvailableOffline,
    'juz not found in offline database': text.failureNotAvailableOffline,
    'failed to load reciters': text.failureContentLoad,
    'failed to load ayah audio': text.failureContentLoad,
    'failed to load chapter audio': text.failureContentLoad,
    'failed to load tafsir': text.failureContentLoad,
    'this translation is already built in': text.failureTranslationBuiltIn,
    'the e-book has no pdf file': text.failureEbookNoPdf,
    'download failed': text.failureDownloadFailed,
    'you already have a plan with this name':
        text.failureQuranPlanDuplicateName,
    'you already have a quran plan with this name':
        text.failureQuranPlanDuplicateName,
    'failed to load quran plans': text.failureQuranPlanLoad,
    'failed to create quran plan': text.failureQuranPlanCreate,
    'failed to update quran plan': text.failureQuranPlanUpdate,
    'failed to load plan details': text.failureQuranPlanDetailsLoad,
    'failed to load plan ayahs': text.failureQuranPlanAyahsLoad,
    'failed to complete plan': text.failureQuranPlanComplete,
    'failed to delete plan': text.failureQuranPlanDelete,
    'plan not found': text.failureQuranPlanNotFound,
  };
  final match = known[key];
  if (match != null) return match;

  final numbers = LanguagePreference.numbers;
  final patterns = <(RegExp, String Function(RegExpMatch))>[
    (
      RegExp(
        r'read every ayah in the plan first:\s*(\d+)\s+of\s+(\d+)\s+still unread',
      ),
      (m) {
        final n = int.tryParse(m[1]!);
        final formatted = n != null ? _commaSeparate(n.toString()) : m[1]!;
        return text.failureQuranPlanUnreadAyahs.fill({
          'count': numbers.digits(formatted),
        });
      },
    ),
    (
      RegExp(r'^request failed \((?:network error)\)$'),
      (_) => text.failureNetwork,
    ),
    (
      RegExp(r'^request failed \((.+)\)$'),
      (m) => text.failureRequestFailed.fill({'code': numbers.digits(m[1]!)}),
    ),
    (
      RegExp(r'^audio download failed \((.+)\)$'),
      (m) => text.failureAudioDownload.fill({'key': numbers.digits(m[1]!)}),
    ),
    (
      RegExp(r'^download interrupted at surah (\d+)\b'),
      (m) => text.failureDownloadInterrupted.fill({'n': numbers.digits(m[1]!)}),
    ),
    (
      RegExp(r'^no translation available for surah (\d+)$'),
      (m) => text.failureNoTranslationSurah.fill({'n': numbers.digits(m[1]!)}),
    ),
    (
      RegExp(
        r'^password must be at least (\d+) characters and include an uppercase',
      ),
      (m) => text.failurePasswordRule.fill({'min': numbers.digits(m[1]!)}),
    ),
    // "Profile response is missing "data"." and the like: a response the app
    // couldn't read, not something the user can act on.
    (RegExp(r' is missing '), (_) => text.failureUnexpectedResponse),
    (RegExp(r' completed without a user$'), (_) => text.failureUnknown),
    (RegExp(r'no auth token was found'), (_) => text.failureUnexpectedResponse),
  ];
  for (final (pattern, build) in patterns) {
    final m = pattern.firstMatch(key);
    if (m != null) return build(m);
  }

  return raw;
}

String _normalize(String raw) {
  var key = raw.trim().toLowerCase();
  while (key.endsWith('.')) {
    key = key.substring(0, key.length - 1).trimRight();
  }
  // Keep the sentence break inside a two-sentence message.
  return key;
}

String _commaSeparate(String digits) {
  final buffer = StringBuffer();
  final len = digits.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
