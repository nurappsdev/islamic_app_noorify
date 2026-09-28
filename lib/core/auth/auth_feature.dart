import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// What the sign-in prompt says for one feature.
///
/// Every gated feature is described once, here, and the shared dialog
/// (`requireLogin`) builds its message from it. A new feature needs a new
/// entry in [AuthFeatures] and nothing else.
///
/// [userAction] and [purpose] feed the generated message, so write them to
/// fit these templates (see [AuthPromptTexts.messageTemplate]):
///
/// * [userAction] finishes "You'd like to ..." - a phrase such as
///   `read the Quran and track your progress`. In Bangla it is the infinitive
///   form that precedes "চান", e.g. `কুরআন পড়তে ও অগ্রগতি সংরক্ষণ করতে`.
/// * [purpose] is a whole sentence on why an account is needed.
///
/// Set [message] only when a hand-written message should replace the
/// generated one.
class AuthFeature {
  const AuthFeature({
    required this.id,
    required this.featureName,
    required this.userAction,
    required this.purpose,
    this.message,
  });

  final String id;

  /// Short name shown as the dialog's heading, e.g. `Quran`.
  final LocalizedText featureName;

  /// What the user is trying to do, as a phrase for the message template.
  final LocalizedText userAction;

  /// Why signing in is needed, as a sentence.
  final LocalizedText purpose;

  /// A hand-written message; when null the message is generated.
  final LocalizedText? message;

  /// The prompt text in [language]: [message] when set, otherwise the
  /// template filled with this feature's [userAction] and [purpose].
  String messageFor(AppLanguage language) {
    final custom = message?.resolve(language) ?? '';
    if (custom.isNotEmpty) return custom;
    return AuthPromptTexts.messageTemplate
        .resolve(language)
        .replaceAll('{action}', userAction.resolve(language))
        .replaceAll('{purpose}', purpose.resolve(language));
  }
}

/// The wording every sign-in prompt shares.
class AuthPromptTexts {
  const AuthPromptTexts._();

  /// Used when a feature has no hand-written message. `{action}` and
  /// `{purpose}` are replaced by the feature's own text.
  static const messageTemplate = LocalizedText(
    en: 'You’d like to {action}. {purpose} Please sign in to continue.',
    bn: 'আপনি {action} চান। {purpose} অনুগ্রহ করে সাইন-ইন করুন।',
  );

  static const notNow = LocalizedText(en: 'Not now', bn: 'এখন নয়');
  static const signIn = LocalizedText(en: 'Sign in', bn: 'সাইন-ইন');
}

/// Every feature that asks a guest to sign in, keyed by [AuthFeature.id].
///
/// To gate a new feature: add an id and an [AuthFeature] to [_registry], then
/// call `requireLogin(context, feature: AuthFeatures.yourFeature)`.
class AuthFeatures {
  const AuthFeatures._();

  static const general = 'general';
  static const quran = 'quran';
  static const salah = 'salah';
  static const amol = 'amol';
  static const hadith = 'hadith';
  static const hadithPlanner = 'hadith_planner';
  static const hadithDashboard = 'hadith_dashboard';
  static const quiz = 'quiz';
  static const quizPlanner = 'quiz_planner';
  static const leaderboard = 'leaderboard';
  static const bookmark = 'bookmark';

  /// The config for [id]; an unknown id gets the general prompt rather than
  /// failing, so a typo can never leave a guest without a login prompt.
  static AuthFeature of(String id) {
    final feature = _registry[id];
    assert(feature != null, 'No AuthFeature registered for "$id".');
    return feature ?? _registry[general]!;
  }

  static const Map<String, AuthFeature> _registry = {
    general: AuthFeature(
      id: general,
      featureName: LocalizedText(en: 'Your account', bn: 'আপনার অ্যাকাউন্ট'),
      userAction: LocalizedText(
        en: 'use this feature',
        bn: 'এই সুবিধাটি ব্যবহার করতে',
      ),
      purpose: LocalizedText(
        en: 'Signing in keeps your progress safe and in sync.',
        bn: 'সাইন-ইন করলে আপনার অগ্রগতি নিরাপদ ও সংরক্ষিত থাকবে।',
      ),
    ),
    quran: AuthFeature(
      id: quran,
      featureName: LocalizedText(en: 'Quran', bn: 'কুরআন'),
      userAction: LocalizedText(
        en: 'read the Holy Quran and save your progress',
        bn: 'কুরআন মাজিদ পড়তে ও আপনার অগ্রগতি সংরক্ষণ করতে',
      ),
      purpose: LocalizedText(
        en: 'Signing in keeps your Quran progress safe.',
        bn: 'সাইন-ইন করলে আপনার কুরআনের অগ্রগতি নিরাপদ থাকবে।',
      ),
      message: LocalizedText(
        en:
            'You’d like to read the Holy Quran and save your progress. To keep '
            'your Quran records and progress safe, please sign in.',
        bn:
            'আপনি কুরআন মাজিদ পড়া এবং আপনার অগ্রগতি সংরক্ষণ করতে চান। আপনার কুরআন '
            'অধ্যায়ের হিসাব ও অগ্রগতি নিরাপদে রাখতে অনুগ্রহ করে আগে সাইন-ইন করুন।',
      ),
    ),
    salah: AuthFeature(
      id: salah,
      featureName: LocalizedText(en: 'Salah tracking', bn: 'সালাত ট্র্যাকিং'),
      userAction: LocalizedText(
        en: 'track your Salah',
        bn: 'আপনার সালাতের আমল ট্র্যাক করতে',
      ),
      purpose: LocalizedText(
        en: 'Signing in saves your daily prayer progress.',
        bn: 'সাইন-ইন করলে আপনার দৈনিক সালাতের অগ্রগতি সংরক্ষিত থাকবে।',
      ),
      message: LocalizedText(
        en:
            'You’d like to track your Salah. To save your daily prayer '
            'progress, please sign in.',
        bn:
            'আপনি আপনার সালাতের আমল ট্র্যাক করতে চান। আপনার দৈনিক সালাতের অগ্রগতি '
            'সংরক্ষণ করতে অনুগ্রহ করে সাইন-ইন করুন।',
      ),
    ),
    amol: AuthFeature(
      id: amol,
      featureName: LocalizedText(en: 'Amol tracker', bn: 'আমল ট্র্যাকার'),
      userAction: LocalizedText(
        en: 'save and track your Amol regularly',
        bn: 'আপনার আমলগুলো নিয়মিতভাবে সংরক্ষণ ও ট্র্যাক করতে',
      ),
      purpose: LocalizedText(
        en: 'Signing in keeps your Amol records safe.',
        bn: 'সাইন-ইন করলে আপনার আমলের হিসাব নিরাপদ থাকবে।',
      ),
      message: LocalizedText(
        en:
            'You’d like to save and track your Amol regularly. Please sign in '
            'to use this feature.',
        bn:
            'আপনি আপনার আমলগুলো নিয়মিতভাবে সংরক্ষণ ও ট্র্যাক করতে চান। এই সুবিধাটি '
            'ব্যবহার করতে আগে সাইন-ইন করুন।',
      ),
    ),
    hadith: AuthFeature(
      id: hadith,
      featureName: LocalizedText(en: 'Hadith reading', bn: 'হাদিস পড়া'),
      userAction: LocalizedText(
        en: 'save your Hadith reading progress',
        bn: 'হাদিস পড়ার অগ্রগতি সংরক্ষণ করতে',
      ),
      purpose: LocalizedText(
        en: 'Signing in keeps your reading history.',
        bn: 'সাইন-ইন করলে আপনার পড়ার ইতিহাস থাকবে।',
      ),
      message: LocalizedText(
        en:
            'You’d like to save your Hadith reading progress. To keep your '
            'reading history, please sign in.',
        bn:
            'আপনি হাদিস পড়ার অগ্রগতি সংরক্ষণ করতে চান। আপনার পড়ার ইতিহাস ধরে রাখতে '
            'অনুগ্রহ করে সাইন-ইন করুন।',
      ),
    ),
    hadithPlanner: AuthFeature(
      id: hadithPlanner,
      featureName: LocalizedText(en: 'Hadith planner', bn: 'হাদিস প্ল্যানার'),
      userAction: LocalizedText(
        en: 'plan your Hadith reading',
        bn: 'আপনার হাদিস পড়ার পরিকল্পনা করতে',
      ),
      purpose: LocalizedText(
        en:
            'Your plans are saved to your account, so you can pick them up '
            'anytime.',
        bn:
            'আপনার পরিকল্পনাগুলো অ্যাকাউন্টে সংরক্ষিত থাকবে, যাতে যেকোনো সময় আবার '
            'শুরু করতে পারেন।',
      ),
    ),
    hadithDashboard: AuthFeature(
      id: hadithDashboard,
      featureName: LocalizedText(
        en: 'Hadith dashboard',
        bn: 'হাদিস ড্যাশবোর্ড',
      ),
      userAction: LocalizedText(
        en: 'see your Hadith reading progress',
        bn: 'আপনার হাদিস পড়ার অগ্রগতি দেখতে',
      ),
      purpose: LocalizedText(
        en: 'Your progress is kept in your account.',
        bn: 'আপনার অগ্রগতি আপনার অ্যাকাউন্টে সংরক্ষিত থাকে।',
      ),
    ),
    quiz: AuthFeature(
      id: quiz,
      featureName: LocalizedText(en: 'Islamic quiz', bn: 'ইসলামিক কুইজ'),
      userAction: LocalizedText(
        en: 'take the Islamic quiz and save your results',
        bn: 'ইসলামিক কুইজে অংশ নিতে এবং আপনার ফলাফল সংরক্ষণ করতে',
      ),
      purpose: LocalizedText(
        en: 'Signing in keeps your quiz progress.',
        bn: 'সাইন-ইন করলে আপনার কুইজের অগ্রগতি থাকবে।',
      ),
      message: LocalizedText(
        en:
            'You’d like to take the Islamic quiz and save your results. To '
            'keep your quiz progress, please sign in.',
        bn:
            'আপনি ইসলামিক কুইজে অংশ নিতে এবং আপনার ফলাফল সংরক্ষণ করতে চান। কুইজের '
            'অগ্রগতি ধরে রাখতে আগে সাইন-ইন করুন।',
      ),
    ),
    quizPlanner: AuthFeature(
      id: quizPlanner,
      featureName: LocalizedText(en: 'Quiz planner', bn: 'কুইজ প্ল্যানার'),
      userAction: LocalizedText(
        en: 'plan your quizzes',
        bn: 'আপনার কুইজের পরিকল্পনা করতে',
      ),
      purpose: LocalizedText(
        en:
            'Your plans are saved to your account, so you can pick them up '
            'anytime.',
        bn:
            'আপনার পরিকল্পনাগুলো অ্যাকাউন্টে সংরক্ষিত থাকবে, যাতে যেকোনো সময় আবার '
            'শুরু করতে পারেন।',
      ),
    ),
    leaderboard: AuthFeature(
      id: leaderboard,
      featureName: LocalizedText(en: 'Leaderboard', bn: 'লিডারবোর্ড'),
      userAction: LocalizedText(
        en: 'see where you stand on the leaderboard',
        bn: 'লিডারবোর্ডে আপনার অবস্থান দেখতে',
      ),
      purpose: LocalizedText(
        en: 'Signing in lets us add your points and show your rank.',
        bn: 'সাইন-ইন করলে আপনার পয়েন্ট যুক্ত হবে এবং আপনার র‍্যাঙ্ক দেখানো যাবে।',
      ),
    ),
    bookmark: AuthFeature(
      id: bookmark,
      featureName: LocalizedText(en: 'Favourites', bn: 'পছন্দের তালিকা'),
      userAction: LocalizedText(
        en: 'save your favourites',
        bn: 'আপনার পছন্দের বিষয়গুলো সংরক্ষণ করতে',
      ),
      purpose: LocalizedText(
        en: 'Signing in keeps your list safe.',
        bn: 'সাইন-ইন করলে আপনার তালিকা নিরাপদ থাকবে।',
      ),
      message: LocalizedText(
        en:
            'You’d like to save your favourites. To keep your list safe, '
            'please sign in.',
        bn:
            'আপনি আপনার পছন্দের বিষয়গুলো সংরক্ষণ করতে চান। আপনার তালিকা নিরাপদ রাখতে '
            'অনুগ্রহ করে সাইন-ইন করুন।',
      ),
    ),
  };
}
