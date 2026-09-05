class ApiConstants {
// local
  static const String baseUrl = "https://siamnahidul7000.ilmifygroup.com/api/v1";

//live
// static const String baseUrl = https://siamnahidul7000.ilmifygroup.com/api/v1";
  static const String imageBaseUrl = "";

  static const String socketBaseUrl = "https://api.drop-dr.com";

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
  static const String signInEndPoint = "/auth/login";
  static const String refreshTokenEndPoint = "/auth/refresh-token";
  static const String accountDelete = "/users/delete";
  static const String verifyEmailEndPoint = "/auth/verify-email";
  static const String updateMoreInformationEndPoint =
      "/employee/update-employee-profile";
  static const String forgotPasswordPoint = "/auth/forgot-password";
  static const String resetPasswordEndPoint = "/auth/reset-password";
  static const String changePasswordEndPoint = "/auth/change-password";
  static const String deleteAccountEndPoint = "/auth/delete-account";
  static const String notification = "/notifications";
  static const String notificationBadgeEndPoint = "/notifications/badge";
  static const String notificationReadAllEndPoint = "/notifications/read-all";

  static String notificationReadEndPoint(String notificationId) =>
      "/notifications/$notificationId/read";

}