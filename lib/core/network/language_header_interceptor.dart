import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Adds an `Accept-Language` header (`bn` / `en`) to every request, so the API
/// answers - including auth messages - in the language the user picked.
///
/// The language is read per request, so a change in settings applies to the
/// next call without rebuilding any client.
class LanguageHeaderInterceptor extends Interceptor {
  const LanguageHeaderInterceptor();

  static const header = 'Accept-Language';

  static String get code =>
      LanguagePreference.current == AppLanguage.english ? 'en' : 'bn';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[header] = code;
    handler.next(options);
  }
}
