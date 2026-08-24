import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'package:islami_app_noorify/core/utils/app_text_bn.dart';
import 'package:islami_app_noorify/core/utils/app_text_en.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_cubit.dart';

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
      monthFebruary: _read(
        map,
        'monthFebruary',
        fallback?.monthFebruary ?? '',
      ),
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
      monthNovember: _read(
        map,
        'monthNovember',
        fallback?.monthNovember ?? '',
      ),
      monthDecember: _read(
        map,
        'monthDecember',
        fallback?.monthDecember ?? '',
      ),
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
    final language = context.watch<LanguageCubit>().state.language;
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
