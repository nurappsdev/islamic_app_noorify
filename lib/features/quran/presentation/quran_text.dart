import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// English and Bangla text for the Quran module, following the app language.
///
/// Numbers go through [n] so Bangla shows Bengali digits, and Surah names
/// through [surahName] so stored English names (bookmarks, playlists, plans)
/// still read in Bangla.
class QuranText {
  const QuranText._(this.isBangla);

  /// Watches the app language; use in `build`. English when no
  /// [LanguageBloc] is above [context] (e.g. a widget shown on its own).
  factory QuranText.of(BuildContext context) => _from(context, listen: true);

  /// Reads the app language once; use in callbacks.
  factory QuranText.read(BuildContext context) => _from(context, listen: false);

  static QuranText _from(BuildContext context, {required bool listen}) {
    try {
      LanguageBloc bloc;
      try {
        bloc = listen
            ? context.watch<LanguageBloc>()
            : context.read<LanguageBloc>();
      } on AssertionError {
        // Outside a build (a tap handler, a dialog builder) watching isn't
        // allowed; the current language still is.
        bloc = context.read<LanguageBloc>();
      }
      return QuranText._(bloc.state.language == AppLanguage.bangla);
    } on ProviderNotFoundException {
      return english;
    }
  }

  static const english = QuranText._(false);
  static const bangla = QuranText._(true);

  final bool isBangla;

  String _t(String en, String bn) => isBangla ? bn : en;

  // ---- Numbers & names ---------------------------------------------------

  static const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  /// [value] with Bengali digits in Bangla.
  String n(Object value) {
    final text = '$value';
    if (!isBangla) return text;
    return text.replaceAllMapped(
      RegExp('[0-9]'),
      (m) => _bnDigits[int.parse(m[0]!)],
    );
  }

  /// The Surah's name in the current language, falling back to [english].
  String surahName(int number, [String english = '']) {
    if (isBangla && number >= 1 && number <= _bnSurahNames.length) {
      return _bnSurahNames[number - 1];
    }
    return english;
  }

  /// "Meccan" / "Medinan" (Makki / Madani) from any spelling the data uses.
  String revelationPlace(String raw) {
    final place = raw.toLowerCase();
    if (place.startsWith('mec') || place.startsWith('mak')) {
      return _t('Meccan', 'মাক্কী');
    }
    if (place.startsWith('med') || place.startsWith('mad')) {
      return _t('Medinan', 'মাদানী');
    }
    return raw;
  }

  /// Hours and minutes, e.g. "2 hr 5 min" / "২ ঘণ্টা ৫ মিনিট".
  String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final hr = _t('hr', 'ঘণ্টা');
    final min = _t('min', 'মিনিট');
    return h > 0 ? '${n(h)} $hr ${n(m)} $min' : '${n(m)} $min';
  }

  // ---- Common ------------------------------------------------------------

  String get quran => _t('Quran', 'কুরআন');
  String get surah => _t('Surah', 'সূরা');
  String get para => _t('Para', 'পারা');
  String get page => _t('Page', 'পৃষ্ঠা');
  String get noResults => _t('No results', 'কিছু পাওয়া যায়নি');
  String get bismillah => _t('Bismillah', 'বিসমিল্লাহ');
  String surahTitle(String name) => '$surah $name';
  String paraTitle(int number) => '$para ${n(number)}';
  String pageTitle(int number) => '$page ${n(number)}';
  String ayahCount(int count) => '${n(count)} ${_t('Ayahs', 'আয়াত')}';
  String ayahLabel(int number) => '${_t('Ayah', 'আয়াত')} ${n(number)}';
  String ayahRange(int from, int to) =>
      '${_t('Ayat', 'আয়াত')} ${n(from)}-${n(to)}';

  String get searchSurahHint => _t('Search Surah...', 'সূরা খুঁজুন...');
  String get noSurahsFound => _t('No Surahs found', 'কোনো সূরা পাওয়া যায়নি');

  // ---- Home --------------------------------------------------------------

  String get tajweedDownload =>
      _t('Tajweed / Download Quran', 'তাজবীদ / কুরআন ডাউনলোড');
  String get searchSurahOrPara =>
      _t('Search Surah Or Para', 'সূরা বা পারা খুঁজুন');
  String get searchPage =>
      _t('Search page, Surah or Para', 'পৃষ্ঠা, সূরা বা পারা খুঁজুন');

  // ---- Saved -------------------------------------------------------------

  String get saved => _t('Saved', 'সংরক্ষিত');
  String get playList => _t('Play List', 'প্লে লিস্ট');
  String get quranPlaylist => _t('Quran Playlist', 'কুরআন প্লেলিস্ট');
  String get createPlaylist => _t('Create Playlist', 'প্লেলিস্ট তৈরি করুন');
  String get editPlaylist => _t('Edit Playlist', 'প্লেলিস্ট সম্পাদনা করুন');
  String get playlistDetails => _t('Playlist Details', 'প্লেলিস্টের বিস্তারিত');
  String get playlistName => _t('Playlist Name', 'প্লেলিস্টের নাম');
  String get playlistDescription => _t('Description', 'বিবরণ');
  String get playlistNameHint =>
      _t('e.g. Daily Recitation', 'যেমন: দৈনন্দিন তিলাওয়াত');
  String get playlistDescriptionHint =>
      _t('Optional description', 'ঐচ্ছিক বিবরণ');
  String get enterPlaylistName =>
      _t('Please enter a playlist name', 'দয়া করে একটি প্লেলিস্টের নাম লিখুন');
  String get selectAtLeastOneItem => _t(
    'Please add at least one Surah or Para',
    'অন্তত একটি সূরা বা পারা যোগ করুন',
  );
  String get addItem => _t('Add Item', 'আইটেম যোগ করুন');
  String get addSurah => _t('Add Surah', 'সূরা যোগ করুন');
  String get addPara => _t('Add Para', 'পারা যোগ করুন');
  String get addAyahsRange => _t('Add Ayah Range', 'নির্দিষ্ট আয়াত যোগ করুন');
  String get noPlaylists => _t('No playlists available', 'কোনো প্লে লিস্ট নেই');
  String get noBookmarks =>
      _t('No saved bookmarks yet', 'এখনো কোনো বুকমার্ক নেই');
  String get noSurahs => _t('No Surahs', 'কোনো সূরা নেই');
  String get noSurahsInPlaylist =>
      _t('No Surahs in this playlist', 'এই প্লে লিস্টে কোনো সূরা নেই');
  String get noItemsInPlaylist =>
      _t('No items in this playlist yet', 'এখনো কোনো আইটেম যোগ করা হয়নি');
  String get emptyPlaylistSub => _t(
    'Create a playlist to start organizing your Quran reading.',
    'আপনার কুরআন পড়া সাজাতে একটি প্লেলিস্ট তৈরি করুন।',
  );
  String get playAll => _t('Play All', 'সব চালান');
  String get deletePlaylistConfirmTitle =>
      _t('Delete Playlist?', 'প্লেলিস্ট মুছে ফেলবেন?');
  String get deletePlaylistConfirmMessage => _t(
    'Are you sure you want to delete this playlist?',
    'আপনি কি নিশ্চিত যে এই প্লেলিস্টটি মুছে ফেলতে চান?',
  );
  String get playlistCreatedSuccessfully =>
      _t('Playlist created successfully', 'প্লেলিস্ট সফলভাবে তৈরি হয়েছে');
  String get playlistUpdatedSuccessfully =>
      _t('Playlist updated successfully', 'প্লেলিস্ট সফলভাবে আপডেট হয়েছে');
  String get playlistDeletedSuccessfully =>
      _t('Playlist deleted successfully', 'প্লেলিস্ট সফলভাবে মুছে ফেলা হয়েছে');
  String get allAyahs => _t('All', 'সব');
  String get readAyahs => _t('Read', 'পড়া হয়েছে');
  String get unreadAyahs => _t('Unread', 'অপঠিত');
  String get juz => _t('Juz', 'পারা');
  String get surahs => _t('Surahs', 'সূরাসমূহ');
  String get paras => _t('Paras', 'পারাসমূহ');
  String get add => _t('Add', 'যোগ করুন');
  String get update => _t('Update', 'আপডেট করুন');
  String get fromAyah => _t('From Ayah', 'শুরুর আয়াত');
  String get toAyah => _t('To Ayah', 'শেষ আয়াত');
  String get ayahRangeLabel => _t('Ayah Range', 'আয়াতের সীমা');
  String get remaining => _t('Remaining', 'বাকি');
  String get totalAyahs => _t('Total Ayahs', 'মোট আয়াত');
  String get retry => _t('Retry', 'আবার চেষ্টা করুন');
  String get somethingWentWrong => _t(
    'Something went wrong. Please try again.',
    'কিছু সমস্যা হয়েছে। আবার চেষ্টা করুন।',
  );

  /// "Sura (Al-Fatiha, Al-Baqarah, ...)" for a playlist's first Surahs.
  String playlistSummary(List<String> names, int total) {
    if (names.isEmpty) return noSurahs;
    return '$surah (${names.join(', ')}${total > names.length ? ', ...' : ''})';
  }

  // ---- Player ------------------------------------------------------------

  String get previousSurah => _t('Previous Surah', 'আগের সূরা');
  String get nextSurah => _t('Next Surah', 'পরের সূরা');
  String get play => _t('Play', 'চালান');
  String get pause => _t('Pause', 'থামান');
  String get finished => _t('Finished', 'শেষ হয়েছে');
  String ayahOf(int ayah, int last) => _t(
    'Ayah ${n(ayah)} of ${n(last)}',
    '${n(last)}-এর মধ্যে আয়াত ${n(ayah)}',
  );

  // ---- Planner -----------------------------------------------------------

  String get myPlan => _t('My Plan', 'আমার পরিকল্পনা');
  String get searchPlan => _t('Search Plan', 'পরিকল্পনা খুঁজুন');
  String get completePlan => _t('Complete Plan', 'সম্পন্ন পরিকল্পনা');
  String get searchPlanHint => _t('Search plan...', 'পরিকল্পনা খুঁজুন...');
  String get createPlan => _t('Create Plan', 'পরিকল্পনা তৈরি করুন');
  String get createPlanTitle => _t('Create plan', 'পরিকল্পনা তৈরি');
  String get create => _t('Create', 'তৈরি করুন');
  String get read => _t('Read', 'পড়ুন');
  String get getStarted => _t('Get Started', 'শুরু করুন');
  String get completed => _t('Completed', 'সম্পন্ন');
  String get markCompleted => _t('Mark Completed', 'সম্পন্ন চিহ্নিত করুন');
  String get deletePlan => _t('Delete Plan', 'প্ল্যান মুছে ফেলুন');
  String get noPlansYet => _t(
    "You haven't created any plan yet !",
    'আপনি এখনো কোনো পরিকল্পনা তৈরি করেননি!',
  );
  String get noCompletedPlansYet => _t(
    "You haven't completed any plan yet !",
    'আপনি এখনো কোনো পরিকল্পনা সম্পন্ন করেননি!',
  );
  String planCreated(String name) => _t(
    'Plan "$name" created successfully!',
    '"$name" পরিকল্পনা তৈরি হয়েছে!',
  );
  String planStarted(String name) =>
      _t('Started "$name"!', '"$name" শুরু হয়েছে!');
  String days(int count) => '${n(count)} ${_t('Days', 'দিন')}';
  String get planName => _t('Plan name', 'পরিকল্পনার নাম');
  String get completionDays => _t('Completion days', 'সম্পন্ন করার দিন');
  String get writeHere => _t('Write Here . . .', 'এখানে লিখুন . . .');
  String get selectStartSurah =>
      _t('Select Start Sura', 'শুরুর সূরা বাছাই করুন');
  String get selectEndSurah => _t('Select End Sura', 'শেষের সূরা বাছাই করুন');
  String get enterPlanName =>
      _t('Please enter a plan name', 'পরিকল্পনার নাম লিখুন');
  String get enterValidDays =>
      _t('Please enter valid completion days', 'সঠিক দিনের সংখ্যা লিখুন');
  String example(String value) => '${_t('Eg', 'যেমন')} : $value';
  String get quranPlan => _t('Quran Plan', 'কুরআন প্ল্যান');
  String get createQuranPlan =>
      _t('Create Quran Plan', 'কুরআন প্ল্যান তৈরি করুন');
  String get targetDays => _t('Target Days', 'লক্ষ্য দিন');
  String get wholeQuran => _t('Whole Quran', 'সম্পূর্ণ কুরআন');
  String get startDate => _t('Start Date', 'শুরুর তারিখ');
  String get endDate => _t('End Date', 'শেষের তারিখ');
  String get daysLeft => _t('Days Left', 'বাকি দিন');
  String get day => _t('Day', 'দিন');
  String get dailyTarget => _t('Daily Target', 'প্রতিদিনের লক্ষ্য');
  String get ayahsCompleted => _t('Ayahs Completed', 'পঠিত আয়াত');
  String get ayahsRemaining => _t('Ayahs Remaining', 'বাকি আয়াত');
  String get progress => _t('Progress', 'অগ্রগতি');
  String get onTrack => _t('On Track', 'সময়সূচি অনুযায়ী');
  String get behindSchedule => _t('Behind Schedule', 'সময়সূচি থেকে পিছিয়ে');
  String get aheadOfSchedule =>
      _t('Ahead of Schedule', 'সময়সূচির চেয়ে এগিয়ে');
  String get overdue => _t('Overdue', 'সময়সীমা অতিক্রম হয়েছে');
  String get completedPlans => _t('Completed Plans', 'সম্পন্ন প্ল্যান');
  String get activePlans => _t('Active Plans', 'চলমান প্ল্যান');
  String get noActivePlans => _t('No Active Plans', 'কোনো চলমান প্ল্যান নেই');
  String get noActivePlansHint => _t(
    'Pick a ready-made plan or create your own, and read a little of the '
        'Quran every day.',
    'একটি তৈরি পরিকল্পনা বেছে নিন বা নিজের পরিকল্পনা তৈরি করুন, আর প্রতিদিন '
        'একটু করে কুরআন পড়ুন।',
  );
  String get exploreReadyPlans =>
      _t('Explore ready-made plans', 'তৈরি পরিকল্পনা দেখুন');

  /// Ayahs still to read today to stay on schedule.
  String todayToGo(int ayahs) =>
      _t('Today: ${n(ayahs)} ayahs to go', 'আজ বাকি: ${n(ayahs)} আয়াত');
  String get todayTargetDone =>
      _t("Today's target done", 'আজকের লক্ষ্য পূরণ হয়েছে');

  /// A preset's reading load, before it is started.
  String aboutPerDay(int ayahs) =>
      _t('about ${n(ayahs)} ayahs a day', 'প্রতিদিন প্রায় ${n(ayahs)} আয়াত');

  /// Where "Continue reading" picks up.
  String continueAt(String surahName, int ayahNo) =>
      '$surahName · ${_t('Ayah', 'আয়াত')} ${n(ayahNo)}';
  String dayOfTotal(int day, int total, int left) => _t(
    'Day ${n(day)} of ${n(total)} · ${n(left)} days left',
    'দিন ${n(day)}/${n(total)} · ${n(left)} দিন বাকি',
  );
  String get markCompletedConfirmTitle => _t(
    'Mark this plan as completed?',
    'পরিকল্পনাটি সম্পন্ন হিসেবে চিহ্নিত করবেন?',
  );
  String get markCompletedConfirmMessage => _t(
    'It moves to Completed. You can reopen it later.',
    'এটি সম্পন্ন তালিকায় চলে যাবে। পরে আবার চালু করতে পারবেন।',
  );
  String get noCompletedPlans =>
      _t('No Completed Plans', 'কোনো সম্পন্ন প্ল্যান নেই');
  String get planCreatedSuccessfully =>
      _t('Plan created successfully!', 'প্ল্যান সফলভাবে তৈরি হয়েছে!');
  String get planUpdatedSuccessfully =>
      _t('Plan updated successfully!', 'প্ল্যান সফলভাবে আপডেট হয়েছে!');
  String get quranPlanDuplicateName => _t(
    'You already have a Quran plan with this name.',
    'এই নামে আপনার ইতোমধ্যে একটি কুরআন প্ল্যান রয়েছে।',
  );
  String get failedToLoadPlans =>
      _t('Failed to load Quran plans.', 'কুরআন প্ল্যান লোড করা যায়নি।');
  String get failedToCreatePlan =>
      _t('Failed to create Quran plan.', 'কুরআন প্ল্যান তৈরি করা যায়নি।');
  String get failedToUpdatePlan =>
      _t('Failed to update Quran plan.', 'কুরআন প্ল্যান আপডেট করা যায়নি।');
  String get todayRemaining => _t("Today's Remaining", 'আজকের বাকি');
  String get todayRemainingAyahs =>
      _t("Today's Remaining Ayahs", 'আজকের বাকি আয়াত');
  String get markInProgress =>
      _t('Mark In Progress', 'চলমান হিসেবে চিহ্নিত করুন');
  String get quranPlanDetails =>
      _t('Quran Plan Details', 'কুরআন প্ল্যানের বিস্তারিত');
  String get description => _t('Description', 'বিবরণ');
  String get overallProgress => _t('Overall Progress', 'সামগ্রিক অগ্রগতি');
  String get currentDay => _t('Current Day', 'বর্তমান দিন');
  String get selectedSurahs => _t('Selected Surahs', 'নির্বাচিত সূরা');
  String get selectedParas => _t('Selected Paras', 'নির্বাচিত পারা');
  String get nextAyah => _t('Next Ayah', 'পরবর্তী আয়াত');
  String get unread => _t('Unread', 'অপঠিত');
  String get all => _t('All', 'সবগুলো');
  String get completePlanAction => _t('Complete Plan', 'প্ল্যান সম্পন্ন করুন');
  String get completeQuranPlan =>
      _t('Complete Quran Plan', 'কুরআন প্ল্যান সম্পন্ন করুন');
  String get deleteQuranPlan =>
      _t('Delete Quran Plan', 'কুরআন প্ল্যান মুছে ফেলুন');
  String get deletePlanConfirmTitle =>
      _t('Delete Quran Plan?', 'কুরআন প্ল্যান মুছে ফেলবেন?');
  String get deletePlanConfirmMessage => _t(
    'Are you sure you want to delete this plan?\nYour plan will no longer appear in your active plans.',
    'আপনি কি নিশ্চিত যে এই প্ল্যানটি মুছে ফেলতে চান?\nপ্ল্যানটি আপনার চলমান প্ল্যানে আর দেখা যাবে না।',
  );
  String get planDeletedSuccessfully =>
      _t('Plan deleted successfully.', 'প্ল্যান সফলভাবে মুছে ফেলা হয়েছে।');
  String get planCompletedSuccessfully =>
      _t('Plan completed successfully.', 'প্ল্যান সফলভাবে সম্পন্ন হয়েছে।');
  String unreadAyahsWarning(int count) => isBangla
      ? 'এই প্ল্যানটি সম্পন্ন করার আগে আপনাকে আরও ${n(count)}টি আয়াত পড়তে হবে।'
      : 'You still have ${n(count)} Ayahs left to read before completing this plan.';
  String get planNotFound => _t('Plan not found.', 'প্ল্যান পাওয়া যায়নি।');
  String get failedToLoadPlanDetails =>
      _t('Failed to load plan details.', 'প্ল্যানের বিস্তারিত লোড করা যায়নি।');
  String get failedToLoadPlanAyahs =>
      _t('Failed to load plan Ayahs.', 'প্ল্যানের আয়াত লোড করা যায়নি।');
  String get failedToCompletePlan =>
      _t('Failed to complete plan.', 'প্ল্যান সম্পন্ন করা যায়নি।');
  String get failedToDeletePlan =>
      _t('Failed to delete plan.', 'প্ল্যান মুছে ফেলা যায়নি।');
  String get editPlan => _t('Edit Plan', 'প্ল্যান সম্পাদনা করুন');
  String get editQuranPlan =>
      _t('Edit Quran Plan', 'কুরআন প্ল্যান সম্পাদনা করুন');
  String get planStatus => _t('Plan Status', 'প্ল্যানের অবস্থা');
  String get viewAllAyahs => _t('View All Ayahs', 'সকল আয়াত দেখুন');
  String get planAyahs => _t('Plan Ayahs', 'প্ল্যানের আয়াত');
  String get cancel => _t('Cancel', 'বাতিল');
  String get delete => _t('Delete', 'মুছে ফেলুন');
  String get save => _t('Save', 'সংরক্ষণ করুন');
  String get ayah => _t('Ayah', 'আয়াত');

  /// Names of the built-in plans, by id; [fallback] for the user's own.
  String presetPlanName(String id, String fallback) => !isBangla
      ? fallback
      : switch (id) {
          'preset_1_month' => 'এক মাসে কুরআন',
          'preset_2_month' => 'দুই মাসে কুরআন',
          'preset_3_month' => 'তিন মাসে কুরআন',
          'preset_juz_amma' => 'আম্মা পারা (৩০তম পারা)',
          'preset_baqarah' => 'সূরা আল-বাকারা',
          _ => fallback,
        };

  // ---- Dashboard ---------------------------------------------------------

  String get offlineNotDownloaded => _t(
    "You're offline, and this hasn't been downloaded yet. Connect to the "
        'internet once to load it; after that it opens offline too.',
    'আপনি অফলাইনে আছেন, আর এটি এখনো ডাউনলোড হয়নি। একবার ইন্টারনেটে যুক্ত '
        'হয়ে খুলুন; এরপর অফলাইনেও খুলবে।',
  );

  String get totalReadingTime =>
      _t('Total Quran Reading time', 'মোট কুরআন পাঠের সময়');

  /// [totalReadingTime] with the window it covers, so it is not mistaken for
  /// today's figure.
  String totalReadingTimeFor({required int days, DateTime? month}) {
    final window = month != null
        ? '${monthName(month.month)} ${n(month.year)}'
        : days == 1
        ? _t('Today', 'আজ')
        : _t('Last ${n(days)} days', 'গত ${n(days)} দিন');
    return '$totalReadingTime ($window)';
  }

  /// A reading time in the same form as the daily figures: minutes to one
  /// decimal under an hour, hours and minutes above.
  String readingDuration(int seconds) => seconds < 3600
      ? minutes((seconds / 6).round() / 10)
      : duration(Duration(seconds: seconds));
  String get mostReadSurah => _t('Most Reading Sura', 'সর্বাধিক পঠিত সূরা');
  String get todaysValue => _t('Todays Value In Graph', 'আজকের পাঠ');

  /// [value] as a whole number when it is one, else to one decimal.
  String decimal(double value) => n(
    value == value.roundToDouble() ? value.toInt() : value.toStringAsFixed(1),
  );

  String minutes(double value) => '${decimal(value)} ${_t('min', 'মিনিট')}';
  String percent(int value) => '${n(value)}%';
  String get todaysReading => _t("Today's reading", 'আজকের পাঠ');
  String readOfGoal(double read, double goal) =>
      '${decimal(read)} / ${minutes(goal)}';
  String minutesLeft(double value) =>
      _t('${minutes(value)} left', 'আর ${minutes(value)} বাকি');
  String get dailyGoalMet => _t('Daily goal met', 'আজকের লক্ষ্য পূরণ হয়েছে');
  String pointsOf(double points, double max) =>
      '${_t('Points', 'পয়েন্ট')} ${decimal(points)}/${decimal(max)}';
  String get streak => _t('Streak', 'ধারাবাহিকতা');
  String get averagePerDay => _t('Avg / day', 'গড় / দিন');
  String get goalDays => _t('Goal met', 'লক্ষ্য পূরণ');
  String get quranCompletion => _t('Quran completion', 'কুরআন সম্পন্ন');
  String ofTotal(int done, int total) => '${n(done)}/${n(total)}';
  String get plansInProgress => _t('Plans in progress', 'চলমান পরিকল্পনা');
  String get plansCompleted => _t('Plans completed', 'সম্পন্ন পরিকল্পনা');
  String get continueReading => _t('Continue reading', 'পড়া চালিয়ে যান');
  String get signInToTrack => _t(
    'Sign in to track your Quran reading',
    'কুরআন পাঠের হিসাব রাখতে সাইন ইন করুন',
  );

  /// The short weekday name of [date].
  String weekdayShort(DateTime date) =>
      weekdaysFromSaturday[(date.weekday + 1) % 7];

  /// Saturday-first short weekday names, as the weekly chart shows them.
  List<String> get weekdaysFromSaturday => isBangla
      ? const ['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র']
      : const ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  String monthName(int month) => (isBangla ? _bnMonths : _enMonths)[month - 1];
  String monthShort(int month) =>
      isBangla ? _bnMonths[month - 1] : _enMonths[month - 1].substring(0, 3);

  static const _enMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _bnMonths = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];
}

/// Bangla Surah names 1–114, as the Quran API spells them.
const _bnSurahNames = [
  'আল-ফাতিহা',
  'আল-বাকারা',
  'আলে ইমরান',
  'আন-নিসা',
  'আল-মায়িদা',
  'আল-আনআম',
  'আল-আরাফ',
  'আল-আনফাল',
  'আত-তাওবা',
  'ইউনুস',
  'হুদ',
  'ইউসুফ',
  'আর-রাদ',
  'ইবরাহিম',
  'আল-হিজর',
  'আন-নাহল',
  'আল-ইসরা',
  'আল-কাহফ',
  'মারইয়াম',
  'ত্বা-হা',
  'আল-আম্বিয়া',
  'আল-হাজ্জ',
  'আল-মুমিনুন',
  'আন-নূর',
  'আল-ফুরকান',
  'আশ-শুআরা',
  'আন-নামল',
  'আল-কাসাস',
  'আল-আনকাবুত',
  'আর-রূম',
  'লুকমান',
  'আস-সাজদা',
  'আল-আহযাব',
  'সাবা',
  'ফাতির',
  'ইয়াসিন',
  'আস-সাফফাত',
  'সোয়াদ',
  'আয-যুমার',
  'গাফির',
  'ফুসসিলাত',
  'আশ-শূরা',
  'আয-যুখরুফ',
  'আদ-দুখান',
  'আল-জাসিয়া',
  'আল-আহকাফ',
  'মুহাম্মাদ',
  'আল-ফাতহ',
  'আল-হুজুরাত',
  'কাফ',
  'আয-যারিয়াত',
  'আত-তূর',
  'আন-নাজম',
  'আল-কামার',
  'আর-রহমান',
  'আল-ওয়াকিআ',
  'আল-হাদিদ',
  'আল-মুজাদালা',
  'আল-হাশর',
  'আল-মুমতাহিনা',
  'আস-সাফ',
  'আল-জুমুআ',
  'আল-মুনাফিকুন',
  'আত-তাগাবুন',
  'আত-তালাক',
  'আত-তাহরিম',
  'আল-মুলক',
  'আল-কলম',
  'আল-হাক্কাহ',
  'আল-মাআরিজ',
  'নূহ',
  'আল-জিন',
  'আল-মুযযাম্মিল',
  'আল-মুদ্দাসসির',
  'আল-কিয়ামাহ',
  'আল-ইনসান',
  'আল-মুরসালাত',
  'আন-নাবা',
  'আন-নাযিআত',
  'আবাসা',
  'আত-তাকভির',
  'আল-ইনফিতার',
  'আল-মুতাফফিফিন',
  'আল-ইনশিকাক',
  'আল-বুরুজ',
  'আত-তারিক',
  'আল-আলা',
  'আল-গাশিয়াহ',
  'আল-ফাজর',
  'আল-বালাদ',
  'আশ-শামস',
  'আল-লাইল',
  'আদ-দুহা',
  'আশ-শারহ',
  'আত-তীন',
  'আল-আলাক',
  'আল-কদর',
  'আল-বাইয়্যিনাহ',
  'আয-যিলযাল',
  'আল-আদিয়াত',
  'আল-কারিআহ',
  'আত-তাকাসুর',
  'আল-আসর',
  'আল-হুমাযাহ',
  'আল-ফীল',
  'কুরাইশ',
  'আল-মাউন',
  'আল-কাউসার',
  'আল-কাফিরুন',
  'আন-নাসর',
  'আল-মাসাদ',
  'আল-ইখলাস',
  'আল-ফালাক',
  'আন-নাস',
];
