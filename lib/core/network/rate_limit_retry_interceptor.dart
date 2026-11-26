import 'dart:async';

import 'package:dio/dio.dart';

/// Waits out a `429 Too Many Requests` and replays the request.
///
/// The API rate-limits per client (`20` requests per second on top of a
/// `5000` per 15 minutes budget), so a screen that fans out several calls at
/// once - the dua dashboard asks for featured duas, categories, the reading
/// summary and the planner together - can trip the per-second limit even
/// though the user did nothing wrong. The server says when the window clears
/// (`Retry-After`, or `RateLimit-Reset`, both in seconds), and for the
/// per-second limit that is the very next second.
///
/// Only safe, repeatable requests are replayed (`GET`/`HEAD` by default): a
/// `POST` could otherwise be applied twice if the server counted it before
/// rejecting it. The write that matters here, `POST /duas/reading/track`, is
/// already queued and resent by `DuaReadingRepositoryImpl`.
///
/// A 429 is passed through untouched - so the caller sees the server's own
/// message - when the attempts run out, when the server names no delay, or
/// when the delay is longer than [maxDelay] (the 15-minute budget is spent;
/// blocking the screen on it would be worse than failing).
class RateLimitRetryInterceptor extends Interceptor {
  const RateLimitRetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.maxDelay = const Duration(seconds: 5),
    this.fallbackDelay = const Duration(milliseconds: 600),
    this.methods = const {'GET', 'HEAD'},
  });

  /// The client whose rate-limited requests are replayed.
  final Dio dio;

  /// How many times one request may be retried before the 429 is returned.
  final int maxRetries;

  /// The longest the interceptor will wait before giving up on a retry.
  final Duration maxDelay;

  /// Used when the response carries no `Retry-After`/`RateLimit-Reset`, or
  /// names `0` seconds (the window clears within the current second).
  final Duration fallbackDelay;

  /// The HTTP methods considered safe to replay, upper-case.
  final Set<String> methods;

  static const _attemptsKey = 'rate_limit_retries';

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (response.statusCode != 429 || !_isReplayable(options)) {
      return handler.next(response);
    }

    final delay = _delayFor(response);
    if (delay == null) return handler.next(response);

    try {
      await Future<void>.delayed(delay);
      handler.resolve(await dio.fetch<dynamic>(_counted(options)));
    } on DioException catch (e) {
      handler.reject(e);
    } catch (_) {
      handler.next(response);
    }
  }

  bool _isReplayable(RequestOptions options) {
    if (!methods.contains(options.method.toUpperCase())) return false;
    return _attemptsOf(options) < maxRetries;
  }

  int _attemptsOf(RequestOptions options) {
    final attempts = options.extra[_attemptsKey];
    return attempts is int ? attempts : 0;
  }

  RequestOptions _counted(RequestOptions options) => options.copyWith(
    extra: {...options.extra, _attemptsKey: _attemptsOf(options) + 1},
  );

  /// How long to wait before replaying, or `null` to give up.
  Duration? _delayFor(Response<dynamic> response) {
    final seconds =
        _secondsOf(response, 'retry-after') ??
        _secondsOf(response, 'ratelimit-reset');
    if (seconds == null) return fallbackDelay;
    if (seconds <= 0) return fallbackDelay;
    final delay = Duration(seconds: seconds);
    return delay > maxDelay ? null : delay;
  }

  /// A delay header as whole seconds, or `null` when it names none. The API
  /// sends plain seconds for both headers; `Retry-After`'s other legal form,
  /// an HTTP date, is not read (`dart:io`'s `HttpDate` does not exist on Web,
  /// which is where this matters most), so it falls back to [fallbackDelay].
  int? _secondsOf(Response<dynamic> response, String name) {
    final raw = response.headers.value(name)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }
}
