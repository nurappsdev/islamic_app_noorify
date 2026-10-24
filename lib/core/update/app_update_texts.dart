import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// The wording of the Google Play update prompts (see
/// `showAppUpdateDialog`).
class AppUpdateTexts {
  const AppUpdateTexts._();

  static const title = LocalizedText(
    en: 'Update available',
    bn: 'নতুন আপডেট এসেছে',
  );
  static const message = LocalizedText(
    en: 'A newer version of Tuhfatul Muslim is ready on Google Play. Update '
        'now to get the latest features and fixes.',
    bn: 'তুহফাতুল মুসলিম-এর নতুন সংস্করণ গুগল প্লে-তে পাওয়া যাচ্ছে। নতুন সুবিধা ও '
        'সমস্যার সমাধান পেতে এখনই আপডেট করুন।',
  );
  static const later = LocalizedText(en: 'Later', bn: 'পরে');
  // Kept short: these sit side by side in a half-width button, where a
  // longer Bangla label wraps to three cramped lines.
  static const updateNow = LocalizedText(en: 'Update Now', bn: 'এখনই আপডেট');

  static const downloadingTitle = LocalizedText(
    en: 'Downloading update',
    bn: 'আপডেট ডাউনলোড হচ্ছে',
  );
  static const downloadingMessage = LocalizedText(
    en: 'The update is downloading in the background. You can keep using the '
        'app - we will let you know when it is ready to install.',
    bn: 'আপডেটটি ব্যাকগ্রাউন্ডে ডাউনলোড হচ্ছে। আপনি অ্যাপ ব্যবহার চালিয়ে যেতে পারেন; '
        'ইনস্টলের জন্য প্রস্তুত হলে আপনাকে জানানো হবে।',
  );
  static const keepBrowsing = LocalizedText(
    en: 'Keep browsing',
    bn: 'ব্যবহার চালিয়ে যান',
  );

  static const readyTitle = LocalizedText(
    en: 'Update ready',
    bn: 'আপডেট প্রস্তুত',
  );
  static const readyMessage = LocalizedText(
    en: 'The update has been downloaded. The app will restart to finish '
        'installing it.',
    bn: 'আপডেটটি ডাউনলোড হয়ে গেছে। ইনস্টল সম্পন্ন করতে অ্যাপটি পুনরায় চালু হবে।',
  );
  static const restartAndInstall = LocalizedText(
    en: 'Restart & install',
    bn: 'ইনস্টল করুন',
  );

  static const downloadFailed = LocalizedText(
    en: 'The update could not be downloaded. Please try again later.',
    bn: 'আপডেটটি ডাউনলোড করা যায়নি। অনুগ্রহ করে পরে আবার চেষ্টা করুন।',
  );
}
