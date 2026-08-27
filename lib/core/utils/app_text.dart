import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'package:islami_app_noorify/core/utils/app_text_bn.dart';
import 'package:islami_app_noorify/core/utils/app_text_en.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class AppText {
  const AppText({
    required this.noorify,
    required this.splashTitle,
    required this.splashQuote,
    required this.emailOrPhoneHint,
    required this.passwordHint,
    required this.forgotPassword,
    required this.login,
    required this.newToNoorify,
    required this.createAccount,
    required this.signUpSubtitle,
    required this.enterYourName,
    required this.emailAddress,
    required this.emailVerification,
    required this.sendOtp,
    required this.otpVerification,
    required this.verify,
    required this.resendIn,
    required this.resetPassword,
    required this.newPassword,
    required this.confirm,
    required this.phoneNo,
    required this.gender,
    required this.male,
    required this.female,
    required this.confirmPassword,
    required this.signUpWithOthers,
    required this.togglePassword,
    required this.iAgreeToThe,
    required this.termsOfServices,
    required this.privacyPolicy,
    required this.alreadyHaveAccount,
    required this.logIn,
    required this.back,
    required this.setAlarm,
    required this.setAllAlarm,
    required this.vibrateAndRing,
    required this.setRingtone,
    required this.vibrate,
    required this.ring,
    required this.searchHere,
    required this.setAlarmBeforePrayer,
    required this.setAlarmFor,
    required this.offsetAtPrayerTime,
    required this.offsetBefore5Min,
    required this.offsetBefore10Min,
    required this.offsetBefore15Min,
    required this.offsetBefore20Min,
    required this.offsetBefore30Min,
    required this.offsetBefore40Min,
    required this.offsetBefore60Min,
    required this.amolTracking,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.point,
    required this.myPoints,
    required this.todaysAmolTrack,
    required this.amolTrack,
    required this.todays,
    required this.averageTodaysDays,
    required this.myPosition,
    required this.myNearestOrCompetitor,
    required this.competitorInitials,
    required this.viewInDashboard,
    required this.categoryFardhPrayer,
    required this.categorySunnahAndWitr,
    required this.categoryQuran,
    required this.categoryNaflSalat,
    required this.categoryHadith,
    required this.categoryQuiz,
    required this.categoryNaflAndMore,
    required this.salahFajr,
    required this.salahDuhr,
    required this.salahAsr,
    required this.salahMagrib,
    required this.salahEsa,
    required this.salahFajrSunnah,
    required this.salahDuhrSunnah,
    required this.salahAsrSunnah,
    required this.salahMagribSunnah,
    required this.salahEsaSunnah,
    required this.salahWitr,
    required this.naflTahajjud,
    required this.naflIshraq,
    required this.naflChast,
    required this.naflAwabin,
    required this.moreSadaqah,
    required this.moreKarzeHasanah,
    required this.moreNaflFasting,
    required this.morePhysicalExercise,
    required this.moreGivenGoodAdvice,
    required this.moreSkillDevelopment,
    required this.infoQuranTilawat,
    required this.infoHadithReading,
    required this.infoGivingQuiz,
    required this.weekdayMonday,
    required this.weekdayTuesday,
    required this.weekdayWednesday,
    required this.weekdayThursday,
    required this.weekdayFriday,
    required this.weekdaySaturday,
    required this.weekdaySunday,
    required this.monthJanuary,
    required this.monthFebruary,
    required this.monthMarch,
    required this.monthApril,
    required this.monthMay,
    required this.monthJune,
    required this.monthJuly,
    required this.monthAugust,
    required this.monthSeptember,
    required this.monthOctober,
    required this.monthNovember,
    required this.monthDecember,
    required this.google,
    required this.facebook,
    required this.authErrorInvalidEmail,
    required this.authErrorUserDisabled,
    required this.authErrorWrongCredentials,
    required this.authErrorAccountNotPasswordBased,
    required this.authErrorEmailInUse,
    required this.authErrorWeakPassword,
    required this.authErrorOperationNotAllowed,
    required this.authErrorRequiresRecentLogin,
    required this.authErrorAccountExistsDifferentCredential,
    required this.authErrorCredentialAlreadyInUse,
    required this.authErrorTooManyRequests,
    required this.authErrorNetworkFailed,
    required this.authErrorGeneric,
    required this.googleAuthErrorNotConfigured,
    required this.googleAuthErrorUiUnavailable,
    required this.googleAuthErrorInterrupted,
    required this.googleAuthErrorGeneric,
    required this.dashboard,
    required this.quizHistory,
    required this.seeAll,
    required this.averageValue,
    required this.dailyQuizValue,
    required this.weeklyQuizValue,
    required this.monthlyQuizValue,
    required this.competitorName,
    required this.quranicScience,
    required this.questionsCountLabel,
    required this.greeting,
    required this.timer,
    required this.notifications,
    required this.featureDua,
    required this.featureDijpr,
    required this.featureAsmaUlHusna,
    required this.featureQuizAndLearn,
    required this.zakatCalculator,
    required this.ageCalculate,
    required this.home,
    required this.todaysHighestValue,
    required this.todays2ndHighest,
    required this.yesterdaysHighest,
    required this.khalidSaifullah,
    required this.myPositionInMonth,
    required this.firstInTheMonth,
    required this.secondInTheMonth,
    required this.lastMonthWinner,
    required this.sehri,
    required this.iftar,
    required this.hijriDatePlaceholder,
    required this.bengaliDatePlaceholder,
    required this.gregorianDatePlaceholder,
    required this.locationPlaceholder,
    required this.viewPrayerTimes,
    required this.sunrise,
    required this.sunset,
    required this.trishal,
    required this.sunriseTimePlaceholder,
    required this.sunsetTimePlaceholder,
    required this.dhuhrPrayerTime,
    required this.prohibitedPrayerTimes,
    required this.jawaal,
    required this.prayerTimesTitle,
    required this.hijriDateUnavailable,
    required this.nextPrefix,
    required this.prayerTimeSuffix,
    required this.prayerFajr,
    required this.prayerDhuhr,
    required this.prayerAsr,
    required this.prayerMaghribAndIftar,
    required this.prayerIsha,
    required this.learning,
    required this.explore,
    required this.exploreQuranicSciences,
    required this.exploreDailyLife,
    required this.exploreIslamicHistory,
    required this.articlesCountLabel,
    required this.recentArticles,
    required this.articleTitleSabr,
    required this.articleTagIslamicGuidance,
    required this.articleExcerptSabr,
    required this.seeMore,
    required this.postDatePlaceholder,
    required this.allArticles,
    required this.articlesDetails,
    required this.testLearning,
    required this.articleFullTextSabr,
    required this.questionProgressLabel,
    required this.questionsTitlePlaceholder,
    required this.answerLabelPrefix,
    required this.quizTimingProgress,
    required this.previous,
    required this.next,
    required this.timesRemainingLabel,
    required this.quizScore,
    required this.testSubjectSabr,
    required this.excellentWorkMessage,
    required this.timeSpent,
    required this.accuracy,
    required this.accuracyHigh,
    required this.whatsNext,
    required this.whatsNextMessage,
    required this.continueToNext,
    required this.retryQuiz,
    required this.overallScore,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.correctAnswersMessage,
    required this.incorrectAnswersMessage,
    required this.viewCorrectAnswer,
    required this.viewIncorrectAnswer,
    required this.plannerPlanOne,
    required this.plannerPlanTwo,
    required this.createPlan,
    required this.myPlan,
    required this.completePlan,
    required this.noCompletedPlansMessage,
    required this.getStart,
    required this.createPlanHeader,
    required this.planNameLabel,
    required this.writeHereHint,
    required this.selectQuizCategory,
    required this.egQuranicScienceHint,
    required this.selectQuiz,
    required this.egQuiz1Hint,
    required this.add,
    required this.create,
    required this.addMore,
    required this.categories,
    required this.quizzesCountLabel,
    required this.seerahAndHistory,
    required this.islamicManners,
    required this.completeTodaysChallenge,
    required this.letsGetStart,
    required this.quranOnlineButton,
    required this.quranOfflineButton,
    required this.offlineQuranTitle,
    required this.offlineQuranSetupPrompt,
    required this.offlineQuranPreparing,
    required this.offlineQuranSetupAction,
    required this.offlineQuranNotNow,
    required this.offlineQuranSetupFailed,
    required this.offlineQuranDownloadAction,
    required this.offlineQuranResume,
    required this.offlineQuranDownloadIntro,
    required this.quranDownloadSurahAudio,
    required this.quranAudioDownloaded,
    required this.highScore,
    required this.quizQuestionProgressLabel,
    required this.fiftyFiftyChance,
    required this.youCompletedTodaysChallenge,
    required this.todaysPointsLabel,
    required this.completedHistory,
    required this.unableToLoadQuizHistory,
    required this.tryAgain,
    required this.questionsWord,
    required this.learn,
    required this.planner,
    required this.profileTitle,
    required this.percentCompleteSuffix,
    required this.mymensingh,
    required this.badgeLabel,
    required this.position,
    required this.pointsWord,
    required this.familyMember,
    required this.brother,
    required this.familyMemberNameAbdullah,
    required this.familyMemberNameSabit,
    required this.familyMemberNameAli,
    required this.logout,
    required this.settingsTitle,
    required this.aboutUs,
    required this.ourProducts,
    required this.adminSupport,
    required this.feedback,
    required this.appLanguage,
    required this.changePassword,
    required this.deleteAccount,
    required this.languageTitle,
    required this.bangla,
    required this.english,
    required this.defaultLabel,
    required this.allFamilyMembers,
    required this.familyMemberNameZulfikur,
    required this.familyMemberNameAsif,
    required this.searchSurah,
    required this.surahsTitle,
    required this.ayahWord,
    required this.surahMeaningOpening,
    required this.surahMeaningCow,
    required this.surahMeaningFamilyOfImran,
    required this.surahMeaningWomen,
    required this.quranIntroSubtitle,
    required this.quranLoadError,
    required this.hifjoQuranTitle,
    required this.lastReadLabel,
    required this.viewReadingHistory,
    required this.ayahNoLabel,
    required this.tabSurah,
    required this.tabPara,
    required this.meccan,
    required this.medinian,
    required this.juzWord,
    required this.startsLabel,
    required this.bookmarksTitle,
    required this.noBookmarksYet,
    required this.readingHistoryTitle,
    required this.noReadingHistoryYet,
    required this.startReadingPrompt,
    required this.viewFullSura,
    required this.viewInAyat,
    required this.pointsLabel,
    required this.yourReadingTimeIs,
    required this.minLabel,
    required this.secLabel,
    required this.viewQuranTafsir,
    required this.selectReciterTitle,
    required this.tafsirTitle,
  });

  final String noorify;
  final String splashTitle;
  final String splashQuote;
  final String emailOrPhoneHint;
  final String passwordHint;
  final String forgotPassword;
  final String login;
  final String newToNoorify;
  final String createAccount;
  final String signUpSubtitle;
  final String enterYourName;
  final String emailAddress;
  final String emailVerification;
  final String sendOtp;
  final String otpVerification;
  final String verify;
  final String resendIn;
  final String resetPassword;
  final String newPassword;
  final String confirm;
  final String phoneNo;
  final String gender;
  final String male;
  final String female;
  final String confirmPassword;
  final String signUpWithOthers;
  final String togglePassword;
  final String iAgreeToThe;
  final String termsOfServices;
  final String privacyPolicy;
  final String alreadyHaveAccount;
  final String logIn;

  // Shared
  final String back;

  // Alarm feature
  final String setAlarm;
  final String setAllAlarm;
  final String vibrateAndRing;
  final String setRingtone;
  final String vibrate;
  final String ring;
  final String searchHere;
  final String setAlarmBeforePrayer;
  final String setAlarmFor;
  final String offsetAtPrayerTime;
  final String offsetBefore5Min;
  final String offsetBefore10Min;
  final String offsetBefore15Min;
  final String offsetBefore20Min;
  final String offsetBefore30Min;
  final String offsetBefore40Min;
  final String offsetBefore60Min;

  // Amol tracking feature
  final String amolTracking;
  final String daily;
  final String weekly;
  final String monthly;
  final String point;
  final String myPoints;
  final String todaysAmolTrack;
  final String amolTrack;
  final String todays;
  final String averageTodaysDays;
  final String myPosition;
  final String myNearestOrCompetitor;
  final String competitorInitials;
  final String viewInDashboard;
  final String categoryFardhPrayer;
  final String categorySunnahAndWitr;
  final String categoryQuran;
  final String categoryNaflSalat;
  final String categoryHadith;
  final String categoryQuiz;
  final String categoryNaflAndMore;
  final String salahFajr;
  final String salahDuhr;
  final String salahAsr;
  final String salahMagrib;
  final String salahEsa;
  final String salahFajrSunnah;
  final String salahDuhrSunnah;
  final String salahAsrSunnah;
  final String salahMagribSunnah;
  final String salahEsaSunnah;
  final String salahWitr;
  final String naflTahajjud;
  final String naflIshraq;
  final String naflChast;
  final String naflAwabin;
  final String moreSadaqah;
  final String moreKarzeHasanah;
  final String moreNaflFasting;
  final String morePhysicalExercise;
  final String moreGivenGoodAdvice;
  final String moreSkillDevelopment;
  final String infoQuranTilawat;
  final String infoHadithReading;
  final String infoGivingQuiz;
  final String weekdayMonday;
  final String weekdayTuesday;
  final String weekdayWednesday;
  final String weekdayThursday;
  final String weekdayFriday;
  final String weekdaySaturday;
  final String weekdaySunday;
  final String monthJanuary;
  final String monthFebruary;
  final String monthMarch;
  final String monthApril;
  final String monthMay;
  final String monthJune;
  final String monthJuly;
  final String monthAugust;
  final String monthSeptember;
  final String monthOctober;
  final String monthNovember;
  final String monthDecember;

  // Shared social labels
  final String google;
  final String facebook;

  // Auth error messages
  final String authErrorInvalidEmail;
  final String authErrorUserDisabled;
  final String authErrorWrongCredentials;
  final String authErrorAccountNotPasswordBased;
  final String authErrorEmailInUse;
  final String authErrorWeakPassword;
  final String authErrorOperationNotAllowed;
  final String authErrorRequiresRecentLogin;
  final String authErrorAccountExistsDifferentCredential;
  final String authErrorCredentialAlreadyInUse;
  final String authErrorTooManyRequests;
  final String authErrorNetworkFailed;
  final String authErrorGeneric;
  final String googleAuthErrorNotConfigured;
  final String googleAuthErrorUiUnavailable;
  final String googleAuthErrorInterrupted;
  final String googleAuthErrorGeneric;

  // Dashboard feature
  final String dashboard;
  final String quizHistory;
  final String seeAll;
  final String averageValue;
  final String dailyQuizValue;
  final String weeklyQuizValue;
  final String monthlyQuizValue;
  final String competitorName;
  final String quranicScience;
  final String questionsCountLabel;

  // Home feature
  final String greeting;
  final String timer;
  final String notifications;
  final String featureDua;
  final String featureDijpr;
  final String featureAsmaUlHusna;
  final String featureQuizAndLearn;
  final String zakatCalculator;
  final String ageCalculate;
  final String home;
  final String todaysHighestValue;
  final String todays2ndHighest;
  final String yesterdaysHighest;
  final String khalidSaifullah;
  final String myPositionInMonth;
  final String firstInTheMonth;
  final String secondInTheMonth;
  final String lastMonthWinner;
  final String sehri;
  final String iftar;
  final String hijriDatePlaceholder;
  final String bengaliDatePlaceholder;
  final String gregorianDatePlaceholder;
  final String locationPlaceholder;
  final String viewPrayerTimes;
  final String sunrise;
  final String sunset;
  final String trishal;
  final String sunriseTimePlaceholder;
  final String sunsetTimePlaceholder;
  final String dhuhrPrayerTime;
  final String prohibitedPrayerTimes;
  final String jawaal;
  final String prayerTimesTitle;
  final String hijriDateUnavailable;
  final String nextPrefix;
  final String prayerTimeSuffix;
  final String prayerFajr;
  final String prayerDhuhr;
  final String prayerAsr;
  final String prayerMaghribAndIftar;
  final String prayerIsha;

  // Learning feature
  final String learning;
  final String explore;
  final String exploreQuranicSciences;
  final String exploreDailyLife;
  final String exploreIslamicHistory;
  final String articlesCountLabel;
  final String recentArticles;
  final String articleTitleSabr;
  final String articleTagIslamicGuidance;
  final String articleExcerptSabr;
  final String seeMore;
  final String postDatePlaceholder;
  final String allArticles;
  final String articlesDetails;
  final String testLearning;
  final String articleFullTextSabr;
  final String questionProgressLabel;
  final String questionsTitlePlaceholder;
  final String answerLabelPrefix;
  final String quizTimingProgress;
  final String previous;
  final String next;
  final String timesRemainingLabel;
  final String quizScore;
  final String testSubjectSabr;
  final String excellentWorkMessage;
  final String timeSpent;
  final String accuracy;
  final String accuracyHigh;
  final String whatsNext;
  final String whatsNextMessage;
  final String continueToNext;
  final String retryQuiz;
  final String overallScore;
  final String correctAnswers;
  final String incorrectAnswers;
  final String correctAnswersMessage;
  final String incorrectAnswersMessage;
  final String viewCorrectAnswer;
  final String viewIncorrectAnswer;

  // Planner feature
  final String plannerPlanOne;
  final String plannerPlanTwo;
  final String createPlan;
  final String myPlan;
  final String completePlan;
  final String noCompletedPlansMessage;
  final String getStart;
  final String createPlanHeader;
  final String planNameLabel;
  final String writeHereHint;
  final String selectQuizCategory;
  final String egQuranicScienceHint;
  final String selectQuiz;
  final String egQuiz1Hint;
  final String add;
  final String create;
  final String addMore;

  // Quiz feature
  final String categories;
  final String quizzesCountLabel;
  final String seerahAndHistory;
  final String islamicManners;
  final String completeTodaysChallenge;
  final String letsGetStart;
  final String quranOnlineButton;
  final String quranOfflineButton;
  final String offlineQuranTitle;
  final String offlineQuranSetupPrompt;
  final String offlineQuranPreparing;
  final String offlineQuranSetupAction;
  final String offlineQuranNotNow;
  final String offlineQuranSetupFailed;
  final String offlineQuranDownloadAction;
  final String offlineQuranResume;
  final String offlineQuranDownloadIntro;
  final String quranDownloadSurahAudio;
  final String quranAudioDownloaded;
  final String highScore;
  final String quizQuestionProgressLabel;
  final String fiftyFiftyChance;
  final String youCompletedTodaysChallenge;
  final String todaysPointsLabel;
  final String completedHistory;
  final String unableToLoadQuizHistory;
  final String tryAgain;
  final String questionsWord;
  final String learn;
  final String planner;

  // Profile feature
  final String profileTitle;
  final String percentCompleteSuffix;
  final String mymensingh;
  final String badgeLabel;
  final String position;
  final String pointsWord;
  final String familyMember;
  final String brother;
  final String familyMemberNameAbdullah;
  final String familyMemberNameSabit;
  final String familyMemberNameAli;
  final String logout;

  // Settings feature
  final String settingsTitle;
  final String aboutUs;
  final String ourProducts;
  final String adminSupport;
  final String feedback;
  final String appLanguage;
  final String changePassword;
  final String deleteAccount;

  // App language feature
  final String languageTitle;
  final String bangla;
  final String english;
  final String defaultLabel;
  final String allFamilyMembers;
  final String familyMemberNameZulfikur;
  final String familyMemberNameAsif;

  // Quran feature
  final String searchSurah;
  final String surahsTitle;
  final String ayahWord;
  final String surahMeaningOpening;
  final String surahMeaningCow;
  final String surahMeaningFamilyOfImran;
  final String surahMeaningWomen;
  final String quranIntroSubtitle;
  final String quranLoadError;
  final String hifjoQuranTitle;
  final String lastReadLabel;
  final String viewReadingHistory;
  final String ayahNoLabel;
  final String tabSurah;
  final String tabPara;
  final String meccan;
  final String medinian;
  final String juzWord;
  final String startsLabel;
  final String bookmarksTitle;
  final String noBookmarksYet;
  final String readingHistoryTitle;
  final String noReadingHistoryYet;
  final String startReadingPrompt;
  final String viewFullSura;
  final String viewInAyat;
  final String pointsLabel;
  final String yourReadingTimeIs;
  final String minLabel;
  final String secLabel;
  final String viewQuranTafsir;
  final String selectReciterTitle;
  final String tafsirTitle;

  String categoryLabel(String key) {
    switch (key) {
      case 'Fardh Prayer':
        return categoryFardhPrayer;
      case 'Sunnah and Witr':
        return categorySunnahAndWitr;
      case 'Quran':
        return categoryQuran;
      case 'Nafl Salat':
        return categoryNaflSalat;
      case 'Hadith':
        return categoryHadith;
      case 'Quiz':
        return categoryQuiz;
      case 'Nafl & more':
        return categoryNaflAndMore;
      default:
        return key;
    }
  }

  List<String> get weekdayNames => [
    weekdayMonday,
    weekdayTuesday,
    weekdayWednesday,
    weekdayThursday,
    weekdayFriday,
    weekdaySaturday,
    weekdaySunday,
  ];

  List<String> get monthNames => [
    monthJanuary,
    monthFebruary,
    monthMarch,
    monthApril,
    monthMay,
    monthJune,
    monthJuly,
    monthAugust,
    monthSeptember,
    monthOctober,
    monthNovember,
    monthDecember,
  ];

  List<String> get alarmOffsetOptions => [
    offsetAtPrayerTime,
    offsetBefore5Min,
    offsetBefore10Min,
    offsetBefore15Min,
    offsetBefore20Min,
    offsetBefore30Min,
    offsetBefore40Min,
    offsetBefore60Min,
  ];

  factory AppText.fromMap(Map<dynamic, dynamic> map, {AppText? fallback}) {
    return AppText(
      noorify: _read(map, 'noorify', fallback?.noorify ?? ''),
      splashTitle: _read(map, 'splashTitle', fallback?.splashTitle ?? ''),
      splashQuote: _read(map, 'splashQuote', fallback?.splashQuote ?? ''),
      emailOrPhoneHint: _read(
        map,
        'emailOrPhoneHint',
        fallback?.emailOrPhoneHint ?? '',
      ),
      passwordHint: _read(map, 'passwordHint', fallback?.passwordHint ?? ''),
      forgotPassword: _read(
        map,
        'forgotPassword',
        fallback?.forgotPassword ?? '',
      ),
      login: _read(map, 'login', fallback?.login ?? ''),
      newToNoorify: _read(map, 'newToNoorify', fallback?.newToNoorify ?? ''),
      createAccount: _read(map, 'createAccount', fallback?.createAccount ?? ''),
      signUpSubtitle: _read(
        map,
        'signUpSubtitle',
        fallback?.signUpSubtitle ?? '',
      ),
      enterYourName: _read(map, 'enterYourName', fallback?.enterYourName ?? ''),
      emailAddress: _read(map, 'emailAddress', fallback?.emailAddress ?? ''),
      emailVerification: _read(
        map,
        'emailVerification',
        fallback?.emailVerification ?? '',
      ),
      sendOtp: _read(map, 'sendOtp', fallback?.sendOtp ?? ''),
      otpVerification: _read(
        map,
        'otpVerification',
        fallback?.otpVerification ?? '',
      ),
      verify: _read(map, 'verify', fallback?.verify ?? ''),
      resendIn: _read(map, 'resendIn', fallback?.resendIn ?? ''),
      resetPassword: _read(map, 'resetPassword', fallback?.resetPassword ?? ''),
      newPassword: _read(map, 'newPassword', fallback?.newPassword ?? ''),
      confirm: _read(map, 'confirm', fallback?.confirm ?? ''),
      phoneNo: _read(map, 'phoneNo', fallback?.phoneNo ?? ''),
      gender: _read(map, 'gender', fallback?.gender ?? ''),
      male: _read(map, 'male', fallback?.male ?? ''),
      female: _read(map, 'female', fallback?.female ?? ''),
      confirmPassword: _read(
        map,
        'confirmPassword',
        fallback?.confirmPassword ?? '',
      ),
      signUpWithOthers: _read(
        map,
        'signUpWithOthers',
        fallback?.signUpWithOthers ?? '',
      ),
      togglePassword: _read(
        map,
        'togglePassword',
        fallback?.togglePassword ?? '',
      ),
      iAgreeToThe: _read(map, 'iAgreeToThe', fallback?.iAgreeToThe ?? ''),
      termsOfServices: _read(
        map,
        'termsOfServices',
        fallback?.termsOfServices ?? '',
      ),
      privacyPolicy: _read(map, 'privacyPolicy', fallback?.privacyPolicy ?? ''),
      alreadyHaveAccount: _read(
        map,
        'alreadyHaveAccount',
        fallback?.alreadyHaveAccount ?? '',
      ),
      logIn: _read(map, 'logIn', fallback?.logIn ?? ''),
      back: _read(map, 'back', fallback?.back ?? ''),
      setAlarm: _read(map, 'setAlarm', fallback?.setAlarm ?? ''),
      setAllAlarm: _read(map, 'setAllAlarm', fallback?.setAllAlarm ?? ''),
      vibrateAndRing: _read(
        map,
        'vibrateAndRing',
        fallback?.vibrateAndRing ?? '',
      ),
      setRingtone: _read(map, 'setRingtone', fallback?.setRingtone ?? ''),
      vibrate: _read(map, 'vibrate', fallback?.vibrate ?? ''),
      ring: _read(map, 'ring', fallback?.ring ?? ''),
      searchHere: _read(map, 'searchHere', fallback?.searchHere ?? ''),
      setAlarmBeforePrayer: _read(
        map,
        'setAlarmBeforePrayer',
        fallback?.setAlarmBeforePrayer ?? '',
      ),
      setAlarmFor: _read(map, 'setAlarmFor', fallback?.setAlarmFor ?? ''),
      offsetAtPrayerTime: _read(
        map,
        'offsetAtPrayerTime',
        fallback?.offsetAtPrayerTime ?? '',
      ),
      offsetBefore5Min: _read(
        map,
        'offsetBefore5Min',
        fallback?.offsetBefore5Min ?? '',
      ),
      offsetBefore10Min: _read(
        map,
        'offsetBefore10Min',
        fallback?.offsetBefore10Min ?? '',
      ),
      offsetBefore15Min: _read(
        map,
        'offsetBefore15Min',
        fallback?.offsetBefore15Min ?? '',
      ),
      offsetBefore20Min: _read(
        map,
        'offsetBefore20Min',
        fallback?.offsetBefore20Min ?? '',
      ),
      offsetBefore30Min: _read(
        map,
        'offsetBefore30Min',
        fallback?.offsetBefore30Min ?? '',
      ),
      offsetBefore40Min: _read(
        map,
        'offsetBefore40Min',
        fallback?.offsetBefore40Min ?? '',
      ),
      offsetBefore60Min: _read(
        map,
        'offsetBefore60Min',
        fallback?.offsetBefore60Min ?? '',
      ),
      amolTracking: _read(map, 'amolTracking', fallback?.amolTracking ?? ''),
      daily: _read(map, 'daily', fallback?.daily ?? ''),
      weekly: _read(map, 'weekly', fallback?.weekly ?? ''),
      monthly: _read(map, 'monthly', fallback?.monthly ?? ''),
      point: _read(map, 'point', fallback?.point ?? ''),
      myPoints: _read(map, 'myPoints', fallback?.myPoints ?? ''),
      todaysAmolTrack: _read(
        map,
        'todaysAmolTrack',
        fallback?.todaysAmolTrack ?? '',
      ),
      amolTrack: _read(map, 'amolTrack', fallback?.amolTrack ?? ''),
      todays: _read(map, 'todays', fallback?.todays ?? ''),
      averageTodaysDays: _read(
        map,
        'averageTodaysDays',
        fallback?.averageTodaysDays ?? '',
      ),
      myPosition: _read(map, 'myPosition', fallback?.myPosition ?? ''),
      myNearestOrCompetitor: _read(
        map,
        'myNearestOrCompetitor',
        fallback?.myNearestOrCompetitor ?? '',
      ),
      competitorInitials: _read(
        map,
        'competitorInitials',
        fallback?.competitorInitials ?? '',
      ),
      viewInDashboard: _read(
        map,
        'viewInDashboard',
        fallback?.viewInDashboard ?? '',
      ),
      categoryFardhPrayer: _read(
        map,
        'categoryFardhPrayer',
        fallback?.categoryFardhPrayer ?? '',
      ),
      categorySunnahAndWitr: _read(
        map,
        'categorySunnahAndWitr',
        fallback?.categorySunnahAndWitr ?? '',
      ),
      categoryQuran: _read(map, 'categoryQuran', fallback?.categoryQuran ?? ''),
      categoryNaflSalat: _read(
        map,
        'categoryNaflSalat',
        fallback?.categoryNaflSalat ?? '',
      ),
      categoryHadith: _read(
        map,
        'categoryHadith',
        fallback?.categoryHadith ?? '',
      ),
      categoryQuiz: _read(map, 'categoryQuiz', fallback?.categoryQuiz ?? ''),
      categoryNaflAndMore: _read(
        map,
        'categoryNaflAndMore',
        fallback?.categoryNaflAndMore ?? '',
      ),
      salahFajr: _read(map, 'salahFajr', fallback?.salahFajr ?? ''),
      salahDuhr: _read(map, 'salahDuhr', fallback?.salahDuhr ?? ''),
      salahAsr: _read(map, 'salahAsr', fallback?.salahAsr ?? ''),
      salahMagrib: _read(map, 'salahMagrib', fallback?.salahMagrib ?? ''),
      salahEsa: _read(map, 'salahEsa', fallback?.salahEsa ?? ''),
      salahFajrSunnah: _read(
        map,
        'salahFajrSunnah',
        fallback?.salahFajrSunnah ?? '',
      ),
      salahDuhrSunnah: _read(
        map,
        'salahDuhrSunnah',
        fallback?.salahDuhrSunnah ?? '',
      ),
      salahAsrSunnah: _read(
        map,
        'salahAsrSunnah',
        fallback?.salahAsrSunnah ?? '',
      ),
      salahMagribSunnah: _read(
        map,
        'salahMagribSunnah',
        fallback?.salahMagribSunnah ?? '',
      ),
      salahEsaSunnah: _read(
        map,
        'salahEsaSunnah',
        fallback?.salahEsaSunnah ?? '',
      ),
      salahWitr: _read(map, 'salahWitr', fallback?.salahWitr ?? ''),
      naflTahajjud: _read(map, 'naflTahajjud', fallback?.naflTahajjud ?? ''),
      naflIshraq: _read(map, 'naflIshraq', fallback?.naflIshraq ?? ''),
      naflChast: _read(map, 'naflChast', fallback?.naflChast ?? ''),
      naflAwabin: _read(map, 'naflAwabin', fallback?.naflAwabin ?? ''),
      moreSadaqah: _read(map, 'moreSadaqah', fallback?.moreSadaqah ?? ''),
      moreKarzeHasanah: _read(
        map,
        'moreKarzeHasanah',
        fallback?.moreKarzeHasanah ?? '',
      ),
      moreNaflFasting: _read(
        map,
        'moreNaflFasting',
        fallback?.moreNaflFasting ?? '',
      ),
      morePhysicalExercise: _read(
        map,
        'morePhysicalExercise',
        fallback?.morePhysicalExercise ?? '',
      ),
      moreGivenGoodAdvice: _read(
        map,
        'moreGivenGoodAdvice',
        fallback?.moreGivenGoodAdvice ?? '',
      ),
      moreSkillDevelopment: _read(
        map,
        'moreSkillDevelopment',
        fallback?.moreSkillDevelopment ?? '',
      ),
      infoQuranTilawat: _read(
        map,
        'infoQuranTilawat',
        fallback?.infoQuranTilawat ?? '',
      ),
      infoHadithReading: _read(
        map,
        'infoHadithReading',
        fallback?.infoHadithReading ?? '',
      ),
      infoGivingQuiz: _read(
        map,
        'infoGivingQuiz',
        fallback?.infoGivingQuiz ?? '',
      ),
      weekdayMonday: _read(map, 'weekdayMonday', fallback?.weekdayMonday ?? ''),
      weekdayTuesday: _read(
        map,
        'weekdayTuesday',
        fallback?.weekdayTuesday ?? '',
      ),
      weekdayWednesday: _read(
        map,
        'weekdayWednesday',
        fallback?.weekdayWednesday ?? '',
      ),
      weekdayThursday: _read(
        map,
        'weekdayThursday',
        fallback?.weekdayThursday ?? '',
      ),
      weekdayFriday: _read(map, 'weekdayFriday', fallback?.weekdayFriday ?? ''),
      weekdaySaturday: _read(
        map,
        'weekdaySaturday',
        fallback?.weekdaySaturday ?? '',
      ),
      weekdaySunday: _read(map, 'weekdaySunday', fallback?.weekdaySunday ?? ''),
      monthJanuary: _read(map, 'monthJanuary', fallback?.monthJanuary ?? ''),
      monthFebruary: _read(map, 'monthFebruary', fallback?.monthFebruary ?? ''),
      monthMarch: _read(map, 'monthMarch', fallback?.monthMarch ?? ''),
      monthApril: _read(map, 'monthApril', fallback?.monthApril ?? ''),
      monthMay: _read(map, 'monthMay', fallback?.monthMay ?? ''),
      monthJune: _read(map, 'monthJune', fallback?.monthJune ?? ''),
      monthJuly: _read(map, 'monthJuly', fallback?.monthJuly ?? ''),
      monthAugust: _read(map, 'monthAugust', fallback?.monthAugust ?? ''),
      monthSeptember: _read(
        map,
        'monthSeptember',
        fallback?.monthSeptember ?? '',
      ),
      monthOctober: _read(map, 'monthOctober', fallback?.monthOctober ?? ''),
      monthNovember: _read(map, 'monthNovember', fallback?.monthNovember ?? ''),
      monthDecember: _read(map, 'monthDecember', fallback?.monthDecember ?? ''),
      google: _read(map, 'google', fallback?.google ?? ''),
      facebook: _read(map, 'facebook', fallback?.facebook ?? ''),
      authErrorInvalidEmail: _read(
        map,
        'authErrorInvalidEmail',
        fallback?.authErrorInvalidEmail ?? '',
      ),
      authErrorUserDisabled: _read(
        map,
        'authErrorUserDisabled',
        fallback?.authErrorUserDisabled ?? '',
      ),
      authErrorWrongCredentials: _read(
        map,
        'authErrorWrongCredentials',
        fallback?.authErrorWrongCredentials ?? '',
      ),
      authErrorAccountNotPasswordBased: _read(
        map,
        'authErrorAccountNotPasswordBased',
        fallback?.authErrorAccountNotPasswordBased ?? '',
      ),
      authErrorEmailInUse: _read(
        map,
        'authErrorEmailInUse',
        fallback?.authErrorEmailInUse ?? '',
      ),
      authErrorWeakPassword: _read(
        map,
        'authErrorWeakPassword',
        fallback?.authErrorWeakPassword ?? '',
      ),
      authErrorOperationNotAllowed: _read(
        map,
        'authErrorOperationNotAllowed',
        fallback?.authErrorOperationNotAllowed ?? '',
      ),
      authErrorRequiresRecentLogin: _read(
        map,
        'authErrorRequiresRecentLogin',
        fallback?.authErrorRequiresRecentLogin ?? '',
      ),
      authErrorAccountExistsDifferentCredential: _read(
        map,
        'authErrorAccountExistsDifferentCredential',
        fallback?.authErrorAccountExistsDifferentCredential ?? '',
      ),
      authErrorCredentialAlreadyInUse: _read(
        map,
        'authErrorCredentialAlreadyInUse',
        fallback?.authErrorCredentialAlreadyInUse ?? '',
      ),
      authErrorTooManyRequests: _read(
        map,
        'authErrorTooManyRequests',
        fallback?.authErrorTooManyRequests ?? '',
      ),
      authErrorNetworkFailed: _read(
        map,
        'authErrorNetworkFailed',
        fallback?.authErrorNetworkFailed ?? '',
      ),
      authErrorGeneric: _read(
        map,
        'authErrorGeneric',
        fallback?.authErrorGeneric ?? '',
      ),
      googleAuthErrorNotConfigured: _read(
        map,
        'googleAuthErrorNotConfigured',
        fallback?.googleAuthErrorNotConfigured ?? '',
      ),
      googleAuthErrorUiUnavailable: _read(
        map,
        'googleAuthErrorUiUnavailable',
        fallback?.googleAuthErrorUiUnavailable ?? '',
      ),
      googleAuthErrorInterrupted: _read(
        map,
        'googleAuthErrorInterrupted',
        fallback?.googleAuthErrorInterrupted ?? '',
      ),
      googleAuthErrorGeneric: _read(
        map,
        'googleAuthErrorGeneric',
        fallback?.googleAuthErrorGeneric ?? '',
      ),
      dashboard: _read(map, 'dashboard', fallback?.dashboard ?? ''),
      quizHistory: _read(map, 'quizHistory', fallback?.quizHistory ?? ''),
      seeAll: _read(map, 'seeAll', fallback?.seeAll ?? ''),
      averageValue: _read(map, 'averageValue', fallback?.averageValue ?? ''),
      dailyQuizValue: _read(
        map,
        'dailyQuizValue',
        fallback?.dailyQuizValue ?? '',
      ),
      weeklyQuizValue: _read(
        map,
        'weeklyQuizValue',
        fallback?.weeklyQuizValue ?? '',
      ),
      monthlyQuizValue: _read(
        map,
        'monthlyQuizValue',
        fallback?.monthlyQuizValue ?? '',
      ),
      competitorName: _read(
        map,
        'competitorName',
        fallback?.competitorName ?? '',
      ),
      quranicScience: _read(
        map,
        'quranicScience',
        fallback?.quranicScience ?? '',
      ),
      questionsCountLabel: _read(
        map,
        'questionsCountLabel',
        fallback?.questionsCountLabel ?? '',
      ),
      greeting: _read(map, 'greeting', fallback?.greeting ?? ''),
      timer: _read(map, 'timer', fallback?.timer ?? ''),
      notifications: _read(map, 'notifications', fallback?.notifications ?? ''),
      featureDua: _read(map, 'featureDua', fallback?.featureDua ?? ''),
      featureDijpr: _read(map, 'featureDijpr', fallback?.featureDijpr ?? ''),
      featureAsmaUlHusna: _read(
        map,
        'featureAsmaUlHusna',
        fallback?.featureAsmaUlHusna ?? '',
      ),
      featureQuizAndLearn: _read(
        map,
        'featureQuizAndLearn',
        fallback?.featureQuizAndLearn ?? '',
      ),
      zakatCalculator: _read(
        map,
        'zakatCalculator',
        fallback?.zakatCalculator ?? '',
      ),
      ageCalculate: _read(map, 'ageCalculate', fallback?.ageCalculate ?? ''),
      home: _read(map, 'home', fallback?.home ?? ''),
      todaysHighestValue: _read(
        map,
        'todaysHighestValue',
        fallback?.todaysHighestValue ?? '',
      ),
      todays2ndHighest: _read(
        map,
        'todays2ndHighest',
        fallback?.todays2ndHighest ?? '',
      ),
      yesterdaysHighest: _read(
        map,
        'yesterdaysHighest',
        fallback?.yesterdaysHighest ?? '',
      ),
      khalidSaifullah: _read(
        map,
        'khalidSaifullah',
        fallback?.khalidSaifullah ?? '',
      ),
      myPositionInMonth: _read(
        map,
        'myPositionInMonth',
        fallback?.myPositionInMonth ?? '',
      ),
      firstInTheMonth: _read(
        map,
        'firstInTheMonth',
        fallback?.firstInTheMonth ?? '',
      ),
      secondInTheMonth: _read(
        map,
        'secondInTheMonth',
        fallback?.secondInTheMonth ?? '',
      ),
      lastMonthWinner: _read(
        map,
        'lastMonthWinner',
        fallback?.lastMonthWinner ?? '',
      ),
      sehri: _read(map, 'sehri', fallback?.sehri ?? ''),
      iftar: _read(map, 'iftar', fallback?.iftar ?? ''),
      hijriDatePlaceholder: _read(
        map,
        'hijriDatePlaceholder',
        fallback?.hijriDatePlaceholder ?? '',
      ),
      bengaliDatePlaceholder: _read(
        map,
        'bengaliDatePlaceholder',
        fallback?.bengaliDatePlaceholder ?? '',
      ),
      gregorianDatePlaceholder: _read(
        map,
        'gregorianDatePlaceholder',
        fallback?.gregorianDatePlaceholder ?? '',
      ),
      locationPlaceholder: _read(
        map,
        'locationPlaceholder',
        fallback?.locationPlaceholder ?? '',
      ),
      viewPrayerTimes: _read(
        map,
        'viewPrayerTimes',
        fallback?.viewPrayerTimes ?? '',
      ),
      sunrise: _read(map, 'sunrise', fallback?.sunrise ?? ''),
      sunset: _read(map, 'sunset', fallback?.sunset ?? ''),
      trishal: _read(map, 'trishal', fallback?.trishal ?? ''),
      sunriseTimePlaceholder: _read(
        map,
        'sunriseTimePlaceholder',
        fallback?.sunriseTimePlaceholder ?? '',
      ),
      sunsetTimePlaceholder: _read(
        map,
        'sunsetTimePlaceholder',
        fallback?.sunsetTimePlaceholder ?? '',
      ),
      dhuhrPrayerTime: _read(
        map,
        'dhuhrPrayerTime',
        fallback?.dhuhrPrayerTime ?? '',
      ),
      prohibitedPrayerTimes: _read(
        map,
        'prohibitedPrayerTimes',
        fallback?.prohibitedPrayerTimes ?? '',
      ),
      jawaal: _read(map, 'jawaal', fallback?.jawaal ?? ''),
      prayerTimesTitle: _read(
        map,
        'prayerTimesTitle',
        fallback?.prayerTimesTitle ?? '',
      ),
      hijriDateUnavailable: _read(
        map,
        'hijriDateUnavailable',
        fallback?.hijriDateUnavailable ?? '',
      ),
      nextPrefix: _read(map, 'nextPrefix', fallback?.nextPrefix ?? ''),
      prayerTimeSuffix: _read(
        map,
        'prayerTimeSuffix',
        fallback?.prayerTimeSuffix ?? '',
      ),
      prayerFajr: _read(map, 'prayerFajr', fallback?.prayerFajr ?? ''),
      prayerDhuhr: _read(map, 'prayerDhuhr', fallback?.prayerDhuhr ?? ''),
      prayerAsr: _read(map, 'prayerAsr', fallback?.prayerAsr ?? ''),
      prayerMaghribAndIftar: _read(
        map,
        'prayerMaghribAndIftar',
        fallback?.prayerMaghribAndIftar ?? '',
      ),
      prayerIsha: _read(map, 'prayerIsha', fallback?.prayerIsha ?? ''),
      learning: _read(map, 'learning', fallback?.learning ?? ''),
      explore: _read(map, 'explore', fallback?.explore ?? ''),
      exploreQuranicSciences: _read(
        map,
        'exploreQuranicSciences',
        fallback?.exploreQuranicSciences ?? '',
      ),
      exploreDailyLife: _read(
        map,
        'exploreDailyLife',
        fallback?.exploreDailyLife ?? '',
      ),
      exploreIslamicHistory: _read(
        map,
        'exploreIslamicHistory',
        fallback?.exploreIslamicHistory ?? '',
      ),
      articlesCountLabel: _read(
        map,
        'articlesCountLabel',
        fallback?.articlesCountLabel ?? '',
      ),
      recentArticles: _read(
        map,
        'recentArticles',
        fallback?.recentArticles ?? '',
      ),
      articleTitleSabr: _read(
        map,
        'articleTitleSabr',
        fallback?.articleTitleSabr ?? '',
      ),
      articleTagIslamicGuidance: _read(
        map,
        'articleTagIslamicGuidance',
        fallback?.articleTagIslamicGuidance ?? '',
      ),
      articleExcerptSabr: _read(
        map,
        'articleExcerptSabr',
        fallback?.articleExcerptSabr ?? '',
      ),
      seeMore: _read(map, 'seeMore', fallback?.seeMore ?? ''),
      postDatePlaceholder: _read(
        map,
        'postDatePlaceholder',
        fallback?.postDatePlaceholder ?? '',
      ),
      allArticles: _read(map, 'allArticles', fallback?.allArticles ?? ''),
      articlesDetails: _read(
        map,
        'articlesDetails',
        fallback?.articlesDetails ?? '',
      ),
      testLearning: _read(map, 'testLearning', fallback?.testLearning ?? ''),
      articleFullTextSabr: _read(
        map,
        'articleFullTextSabr',
        fallback?.articleFullTextSabr ?? '',
      ),
      questionProgressLabel: _read(
        map,
        'questionProgressLabel',
        fallback?.questionProgressLabel ?? '',
      ),
      questionsTitlePlaceholder: _read(
        map,
        'questionsTitlePlaceholder',
        fallback?.questionsTitlePlaceholder ?? '',
      ),
      answerLabelPrefix: _read(
        map,
        'answerLabelPrefix',
        fallback?.answerLabelPrefix ?? '',
      ),
      quizTimingProgress: _read(
        map,
        'quizTimingProgress',
        fallback?.quizTimingProgress ?? '',
      ),
      previous: _read(map, 'previous', fallback?.previous ?? ''),
      next: _read(map, 'next', fallback?.next ?? ''),
      timesRemainingLabel: _read(
        map,
        'timesRemainingLabel',
        fallback?.timesRemainingLabel ?? '',
      ),
      quizScore: _read(map, 'quizScore', fallback?.quizScore ?? ''),
      testSubjectSabr: _read(
        map,
        'testSubjectSabr',
        fallback?.testSubjectSabr ?? '',
      ),
      excellentWorkMessage: _read(
        map,
        'excellentWorkMessage',
        fallback?.excellentWorkMessage ?? '',
      ),
      timeSpent: _read(map, 'timeSpent', fallback?.timeSpent ?? ''),
      accuracy: _read(map, 'accuracy', fallback?.accuracy ?? ''),
      accuracyHigh: _read(map, 'accuracyHigh', fallback?.accuracyHigh ?? ''),
      whatsNext: _read(map, 'whatsNext', fallback?.whatsNext ?? ''),
      whatsNextMessage: _read(
        map,
        'whatsNextMessage',
        fallback?.whatsNextMessage ?? '',
      ),
      continueToNext: _read(
        map,
        'continueToNext',
        fallback?.continueToNext ?? '',
      ),
      retryQuiz: _read(map, 'retryQuiz', fallback?.retryQuiz ?? ''),
      overallScore: _read(map, 'overallScore', fallback?.overallScore ?? ''),
      correctAnswers: _read(
        map,
        'correctAnswers',
        fallback?.correctAnswers ?? '',
      ),
      incorrectAnswers: _read(
        map,
        'incorrectAnswers',
        fallback?.incorrectAnswers ?? '',
      ),
      correctAnswersMessage: _read(
        map,
        'correctAnswersMessage',
        fallback?.correctAnswersMessage ?? '',
      ),
      incorrectAnswersMessage: _read(
        map,
        'incorrectAnswersMessage',
        fallback?.incorrectAnswersMessage ?? '',
      ),
      viewCorrectAnswer: _read(
        map,
        'viewCorrectAnswer',
        fallback?.viewCorrectAnswer ?? '',
      ),
      viewIncorrectAnswer: _read(
        map,
        'viewIncorrectAnswer',
        fallback?.viewIncorrectAnswer ?? '',
      ),
      plannerPlanOne: _read(
        map,
        'plannerPlanOne',
        fallback?.plannerPlanOne ?? '',
      ),
      plannerPlanTwo: _read(
        map,
        'plannerPlanTwo',
        fallback?.plannerPlanTwo ?? '',
      ),
      createPlan: _read(map, 'createPlan', fallback?.createPlan ?? ''),
      myPlan: _read(map, 'myPlan', fallback?.myPlan ?? ''),
      completePlan: _read(map, 'completePlan', fallback?.completePlan ?? ''),
      noCompletedPlansMessage: _read(
        map,
        'noCompletedPlansMessage',
        fallback?.noCompletedPlansMessage ?? '',
      ),
      getStart: _read(map, 'getStart', fallback?.getStart ?? ''),
      createPlanHeader: _read(
        map,
        'createPlanHeader',
        fallback?.createPlanHeader ?? '',
      ),
      planNameLabel: _read(map, 'planNameLabel', fallback?.planNameLabel ?? ''),
      writeHereHint: _read(map, 'writeHereHint', fallback?.writeHereHint ?? ''),
      selectQuizCategory: _read(
        map,
        'selectQuizCategory',
        fallback?.selectQuizCategory ?? '',
      ),
      egQuranicScienceHint: _read(
        map,
        'egQuranicScienceHint',
        fallback?.egQuranicScienceHint ?? '',
      ),
      selectQuiz: _read(map, 'selectQuiz', fallback?.selectQuiz ?? ''),
      egQuiz1Hint: _read(map, 'egQuiz1Hint', fallback?.egQuiz1Hint ?? ''),
      add: _read(map, 'add', fallback?.add ?? ''),
      create: _read(map, 'create', fallback?.create ?? ''),
      addMore: _read(map, 'addMore', fallback?.addMore ?? ''),
      categories: _read(map, 'categories', fallback?.categories ?? ''),
      quizzesCountLabel: _read(
        map,
        'quizzesCountLabel',
        fallback?.quizzesCountLabel ?? '',
      ),
      seerahAndHistory: _read(
        map,
        'seerahAndHistory',
        fallback?.seerahAndHistory ?? '',
      ),
      islamicManners: _read(
        map,
        'islamicManners',
        fallback?.islamicManners ?? '',
      ),
      completeTodaysChallenge: _read(
        map,
        'completeTodaysChallenge',
        fallback?.completeTodaysChallenge ?? '',
      ),
      letsGetStart: _read(map, 'letsGetStart', fallback?.letsGetStart ?? ''),
      quranOnlineButton: _read(
        map,
        'quranOnlineButton',
        fallback?.quranOnlineButton ?? '',
      ),
      quranOfflineButton: _read(
        map,
        'quranOfflineButton',
        fallback?.quranOfflineButton ?? '',
      ),
      offlineQuranTitle: _read(
        map,
        'offlineQuranTitle',
        fallback?.offlineQuranTitle ?? '',
      ),
      offlineQuranSetupPrompt: _read(
        map,
        'offlineQuranSetupPrompt',
        fallback?.offlineQuranSetupPrompt ?? '',
      ),
      offlineQuranPreparing: _read(
        map,
        'offlineQuranPreparing',
        fallback?.offlineQuranPreparing ?? '',
      ),
      offlineQuranSetupAction: _read(
        map,
        'offlineQuranSetupAction',
        fallback?.offlineQuranSetupAction ?? '',
      ),
      offlineQuranNotNow: _read(
        map,
        'offlineQuranNotNow',
        fallback?.offlineQuranNotNow ?? '',
      ),
      offlineQuranSetupFailed: _read(
        map,
        'offlineQuranSetupFailed',
        fallback?.offlineQuranSetupFailed ?? '',
      ),
      offlineQuranDownloadAction: _read(
        map,
        'offlineQuranDownloadAction',
        fallback?.offlineQuranDownloadAction ?? '',
      ),
      offlineQuranResume: _read(
        map,
        'offlineQuranResume',
        fallback?.offlineQuranResume ?? '',
      ),
      offlineQuranDownloadIntro: _read(
        map,
        'offlineQuranDownloadIntro',
        fallback?.offlineQuranDownloadIntro ?? '',
      ),
      quranDownloadSurahAudio: _read(
        map,
        'quranDownloadSurahAudio',
        fallback?.quranDownloadSurahAudio ?? '',
      ),
      quranAudioDownloaded: _read(
        map,
        'quranAudioDownloaded',
        fallback?.quranAudioDownloaded ?? '',
      ),
      highScore: _read(map, 'highScore', fallback?.highScore ?? ''),
      quizQuestionProgressLabel: _read(
        map,
        'quizQuestionProgressLabel',
        fallback?.quizQuestionProgressLabel ?? '',
      ),
      fiftyFiftyChance: _read(
        map,
        'fiftyFiftyChance',
        fallback?.fiftyFiftyChance ?? '',
      ),
      youCompletedTodaysChallenge: _read(
        map,
        'youCompletedTodaysChallenge',
        fallback?.youCompletedTodaysChallenge ?? '',
      ),
      todaysPointsLabel: _read(
        map,
        'todaysPointsLabel',
        fallback?.todaysPointsLabel ?? '',
      ),
      completedHistory: _read(
        map,
        'completedHistory',
        fallback?.completedHistory ?? '',
      ),
      unableToLoadQuizHistory: _read(
        map,
        'unableToLoadQuizHistory',
        fallback?.unableToLoadQuizHistory ?? '',
      ),
      tryAgain: _read(map, 'tryAgain', fallback?.tryAgain ?? ''),
      questionsWord: _read(map, 'questionsWord', fallback?.questionsWord ?? ''),
      learn: _read(map, 'learn', fallback?.learn ?? ''),
      planner: _read(map, 'planner', fallback?.planner ?? ''),
      profileTitle: _read(map, 'profileTitle', fallback?.profileTitle ?? ''),
      percentCompleteSuffix: _read(
        map,
        'percentCompleteSuffix',
        fallback?.percentCompleteSuffix ?? '',
      ),
      mymensingh: _read(map, 'mymensingh', fallback?.mymensingh ?? ''),
      badgeLabel: _read(map, 'badgeLabel', fallback?.badgeLabel ?? ''),
      position: _read(map, 'position', fallback?.position ?? ''),
      pointsWord: _read(map, 'pointsWord', fallback?.pointsWord ?? ''),
      familyMember: _read(map, 'familyMember', fallback?.familyMember ?? ''),
      brother: _read(map, 'brother', fallback?.brother ?? ''),
      familyMemberNameAbdullah: _read(
        map,
        'familyMemberNameAbdullah',
        fallback?.familyMemberNameAbdullah ?? '',
      ),
      familyMemberNameSabit: _read(
        map,
        'familyMemberNameSabit',
        fallback?.familyMemberNameSabit ?? '',
      ),
      familyMemberNameAli: _read(
        map,
        'familyMemberNameAli',
        fallback?.familyMemberNameAli ?? '',
      ),
      logout: _read(map, 'logout', fallback?.logout ?? ''),
      settingsTitle: _read(map, 'settingsTitle', fallback?.settingsTitle ?? ''),
      aboutUs: _read(map, 'aboutUs', fallback?.aboutUs ?? ''),
      ourProducts: _read(map, 'ourProducts', fallback?.ourProducts ?? ''),
      adminSupport: _read(map, 'adminSupport', fallback?.adminSupport ?? ''),
      feedback: _read(map, 'feedback', fallback?.feedback ?? ''),
      appLanguage: _read(map, 'appLanguage', fallback?.appLanguage ?? ''),
      changePassword: _read(
        map,
        'changePassword',
        fallback?.changePassword ?? '',
      ),
      deleteAccount: _read(map, 'deleteAccount', fallback?.deleteAccount ?? ''),
      languageTitle: _read(map, 'languageTitle', fallback?.languageTitle ?? ''),
      bangla: _read(map, 'bangla', fallback?.bangla ?? ''),
      english: _read(map, 'english', fallback?.english ?? ''),
      defaultLabel: _read(map, 'defaultLabel', fallback?.defaultLabel ?? ''),
      allFamilyMembers: _read(
        map,
        'allFamilyMembers',
        fallback?.allFamilyMembers ?? '',
      ),
      familyMemberNameZulfikur: _read(
        map,
        'familyMemberNameZulfikur',
        fallback?.familyMemberNameZulfikur ?? '',
      ),
      familyMemberNameAsif: _read(
        map,
        'familyMemberNameAsif',
        fallback?.familyMemberNameAsif ?? '',
      ),
      searchSurah: _read(map, 'searchSurah', fallback?.searchSurah ?? ''),
      surahsTitle: _read(map, 'surahsTitle', fallback?.surahsTitle ?? ''),
      ayahWord: _read(map, 'ayahWord', fallback?.ayahWord ?? ''),
      surahMeaningOpening: _read(
        map,
        'surahMeaningOpening',
        fallback?.surahMeaningOpening ?? '',
      ),
      surahMeaningCow: _read(
        map,
        'surahMeaningCow',
        fallback?.surahMeaningCow ?? '',
      ),
      surahMeaningFamilyOfImran: _read(
        map,
        'surahMeaningFamilyOfImran',
        fallback?.surahMeaningFamilyOfImran ?? '',
      ),
      surahMeaningWomen: _read(
        map,
        'surahMeaningWomen',
        fallback?.surahMeaningWomen ?? '',
      ),
      quranIntroSubtitle: _read(
        map,
        'quranIntroSubtitle',
        fallback?.quranIntroSubtitle ?? '',
      ),
      quranLoadError: _read(
        map,
        'quranLoadError',
        fallback?.quranLoadError ?? '',
      ),
      hifjoQuranTitle: _read(
        map,
        'hifjoQuranTitle',
        fallback?.hifjoQuranTitle ?? '',
      ),
      lastReadLabel: _read(
        map,
        'lastReadLabel',
        fallback?.lastReadLabel ?? '',
      ),
      viewReadingHistory: _read(
        map,
        'viewReadingHistory',
        fallback?.viewReadingHistory ?? '',
      ),
      ayahNoLabel: _read(map, 'ayahNoLabel', fallback?.ayahNoLabel ?? ''),
      tabSurah: _read(map, 'tabSurah', fallback?.tabSurah ?? ''),
      tabPara: _read(map, 'tabPara', fallback?.tabPara ?? ''),
      meccan: _read(map, 'meccan', fallback?.meccan ?? ''),
      medinian: _read(map, 'medinian', fallback?.medinian ?? ''),
      juzWord: _read(map, 'juzWord', fallback?.juzWord ?? ''),
      startsLabel: _read(map, 'startsLabel', fallback?.startsLabel ?? ''),
      bookmarksTitle: _read(
        map,
        'bookmarksTitle',
        fallback?.bookmarksTitle ?? '',
      ),
      noBookmarksYet: _read(
        map,
        'noBookmarksYet',
        fallback?.noBookmarksYet ?? '',
      ),
      readingHistoryTitle: _read(
        map,
        'readingHistoryTitle',
        fallback?.readingHistoryTitle ?? '',
      ),
      noReadingHistoryYet: _read(
        map,
        'noReadingHistoryYet',
        fallback?.noReadingHistoryYet ?? '',
      ),
      startReadingPrompt: _read(
        map,
        'startReadingPrompt',
        fallback?.startReadingPrompt ?? '',
      ),
      viewFullSura: _read(map, 'viewFullSura', fallback?.viewFullSura ?? ''),
      viewInAyat: _read(map, 'viewInAyat', fallback?.viewInAyat ?? ''),
      pointsLabel: _read(map, 'pointsLabel', fallback?.pointsLabel ?? ''),
      yourReadingTimeIs: _read(
        map,
        'yourReadingTimeIs',
        fallback?.yourReadingTimeIs ?? '',
      ),
      minLabel: _read(map, 'minLabel', fallback?.minLabel ?? ''),
      secLabel: _read(map, 'secLabel', fallback?.secLabel ?? ''),
      viewQuranTafsir: _read(
        map,
        'viewQuranTafsir',
        fallback?.viewQuranTafsir ?? '',
      ),
      selectReciterTitle: _read(
        map,
        'selectReciterTitle',
        fallback?.selectReciterTitle ?? '',
      ),
      tafsirTitle: _read(map, 'tafsirTitle', fallback?.tafsirTitle ?? ''),
    );
  }

  static final AppText _fallbackEnglish = AppText.fromMap(appTextEn);
  static final AppText _fallbackBangla = AppText.fromMap(appTextBn);

  static final Map<AppLanguage, AppText> _cache = <AppLanguage, AppText>{
    AppLanguage.english: _fallbackEnglish,
    AppLanguage.bangla: _fallbackBangla,
  };

  static Future<void> load() async {
    _cache[AppLanguage.english] = await _loadFile(
      'assets/language/en.json',
      _fallbackEnglish,
    );
    _cache[AppLanguage.bangla] = await _loadFile(
      'assets/language/bn.json',
      _fallbackBangla,
    );
  }

  static AppText of(BuildContext context) {
    final language = context.watch<LanguageBloc>().state.language;
    return forLanguage(language);
  }

  static AppText forLanguage(AppLanguage language) {
    return _cache[language] ??
        (language == AppLanguage.bangla ? _fallbackBangla : _fallbackEnglish);
  }

  static Future<AppText> _loadFile(String path, AppText fallback) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return fallback;
      return AppText.fromMap(decoded, fallback: fallback);
    } catch (_) {
      return fallback;
    }
  }

  static String _read(Map<dynamic, dynamic> json, String key, String fallback) {
    final value = json[key];
    if (value is! String) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }
}
