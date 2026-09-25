class ApiConstants {
  // local
  static const String baseUrl =
      "https://server-tuhfatulmuslim.ilmifygroup.com/api/v1";

  //live
  // static const String baseUrl = https://siamnahidul7000.ilmifygroup.com/api/v1";
  static const String imageBaseUrl = "";

  // static const String socketBaseUrl = "https://api.drop-dr.com";

  // static const String baseUrl = "https://health-mamun.sarv.live/api/v1";
  // static const String imageBaseUrl = "https://health-mamun.sarv.live/uploads/";
  // static const String socketBaseUrl = "https://health-mamun.sarv.live";

  /// client key
  ///AIzaSyAxaYzHRBhydkW_TwUGHeRYSUV2iCc_uuk
  static const String mapAPIEndPoint =
      "AIzaSyAxaYzHRBhydkW_TwUGHeRYSUV2iCc_uuk";

  // from maqmun bro
  //static const String mapAPIEndPoint = "AIzaSyBTNR1NWw7LcTsEJTTogqVZ39tgY--eD5U";

  /// amader key
  //static const String mapAPIEndPoint = "AIzaSyA-Iri6x5mzNv45XO3a-Ew3z4nvF4CdYo0";

  static const String signUpEndPoint = "/auth/register";
  static const String verifyEmailEndPoint = "/auth/verify-otp";
  static const String resendOtpEndPoint = "/auth/resend-otp";
  static const String signInEndPoint = "/auth/login";
  static const String forgotPasswordPoint = "/auth/forgot-password";
  static const String resetPasswordEndPoint = "/auth/reset-password";

  static const String refreshTokenEndPoint = "/auth/refresh-token";
  static const String accountDelete = "/users/delete";
  static const String getProfileEndPoint = "/user/me";
  static const String updateProfileEndPoint = "/user/me";
  static const String s3UploadEndPoint = "/s3/upload";
  static const String profileImagesPrimaryPath = "Profile_Images";
  static const String familyMembersEndPoint = "/user/family";
  static const String homeDashboardEndPoint = "/home/dashboard";
  static const String amolTrackerDailyEndPoint = "/amol/tracker/daily";
  static const String amolTrackerLogItemEndPoint = "/amol/tracker/log-item";
  static const String amolTrackerDeleteItemEndPoint =
      "/amol/tracker/delete-item";
  static const String amolAnalyticsGraphEndPoint = "/amol/analytics/graph";

  static const String termsOfServiceEndPoint = "/settings/terms-of-service";
  static const String privacyPolicyEndPoint = "/settings/privacy-policy";

  static const String leaderboardTopEndPoint = "/leaderboard/top";

  static const String hadithBooksListEndPoint = "/hadiths/books/lists";
  static const String hadithCategoriesEndPoint = "/hadiths/categories";
  static const String hadithsEndPoint = "/hadiths";
  static const String hadithReadingTrackEndPoint = "/learning/reading/track";
  static const String hadithReadingProgressCategoriesEndPoint =
      "/hadiths/reading/progress/categories";
  static const String hadithReadingProgressSubCategoriesEndPoint =
      "/hadiths/reading/progress/sub-categories";
  static const String hadithLastReadEndPoint = "/hadiths/reading/last-read";
  static const String hadithReadingHistoryEndPoint =
      "/learning/reading/history";
  static const String hadithReadingCompareEndPoint =
      "/hadiths/reading/history/compare";
  static const String hadithReadingRecentEndPoint = "/hadiths/reading/recent";
  static const String hadithReadingReadEndPoint = "/hadiths/reading/read";
  static const String hadithPlansEndPoint = "/hadiths/plans";

  /// One plan: `PATCH` renames / edits it, `DELETE` removes it.
  static String hadithPlanEndPoint(String id) => "$hadithPlansEndPoint/$id";

  /// The hadiths of one plan, each with its read state.
  static String hadithPlanHadithsEndPoint(String id) =>
      "${hadithPlanEndPoint(id)}/hadiths";

  static const String ebooksEndPoint = "/ebooks";

  static String hadithSubCategoriesEndPoint(String categoryId) =>
      "$hadithCategoriesEndPoint/$categoryId/subcategories";

  static const String asmaUlHusnaEndPoint = "/asma-ul-husna";

  static String asmaUlHusnaDetailEndPoint(String id) =>
      "$asmaUlHusnaEndPoint/$id";

  static const String alarmsDashboardEndPoint = "/alarms";
  static const String alarmsCustomEndPoint = "/alarms/custom";
  static const String alarmsRingtonesEndPoint = "/alarms/ringtones";
  static const String alarmsPrayersBatchEndPoint = "/alarms/prayers/batch";

  static String alarmCustomItemEndPoint(String id) =>
      "$alarmsCustomEndPoint/$id";

  static String alarmRingtoneItemEndPoint(String id) =>
      "$alarmsRingtonesEndPoint/$id";

  static const String updateMoreInformationEndPoint =
      "/employee/update-employee-profile";

  static const String changePasswordEndPoint = "/auth/change-password";
  static const String deleteAccountEndPoint = "/auth/delete-account";
  static const String notification = "/notifications";
  static const String notificationBadgeEndPoint = "/notifications/badge";
  static const String notificationReadAllEndPoint = "/notifications/read-all";

  static String notificationReadEndPoint(String notificationId) =>
      "/notifications/$notificationId/read";
}
