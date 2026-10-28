import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/services/google_auth_config.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/google_sign_in_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/repositories/account_repository_impl.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/google_sign_in_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/usecases/google_sign_in_user.dart';

/// Answers each request by path and remembers what was sent.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.routes);

  /// `"METHOD /path"` -> (status, body). A missing route answers 404.
  final Map<String, (int, Object)> routes;
  final requests = <RequestOptions>[];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.uri.path.split('/api/v1').last}';
    final (status, body) =
        routes[key] ?? (404, {'success': false, 'message': 'API not found'});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// In-memory stand-in for the Hive-backed session store.
class _FakeLocal implements AuthLocalDataSource {
  String? token;

  @override
  Future<void> cacheToken(String value) async => token = value;

  @override
  String? getToken() => token;

  @override
  bool get hasToken => token != null;

  @override
  Future<void> clearToken() async => token = null;
}

({AuthRemoteDataSourceImpl source, _StubAdapter http}) _setup(
  Map<String, (int, Object)> routes,
) {
  final http = _StubAdapter(routes);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test/api/v1',
      validateStatus: (s) => s != null && s < 500,
    ),
  )..httpClientAdapter = http;
  return (source: AuthRemoteDataSourceImpl(dio: dio), http: http);
}

void main() {
  group('GoogleSignInRequestModel', () {
    test('sends only the ID token when there is no FCM token', () {
      final json = const GoogleSignInRequestModel(idToken: 'tok').toJson();
      expect(json, {'idToken': 'tok'});
      // No platform key either: it only travels with an FCM token.
      expect(json.containsKey('platform'), isFalse);
    });

    test('adds the FCM token and platform when one is available', () {
      final json = const GoogleSignInRequestModel(
        idToken: 'tok',
        fcmToken: 'fcm',
      ).toJson();
      expect(json['idToken'], 'tok');
      expect(json['fcmToken'], 'fcm');
      expect(json['platform'], isNotEmpty);
    });

    test('an empty FCM token is left out rather than sent blank', () {
      final json = const GoogleSignInRequestModel(
        idToken: 'tok',
        fcmToken: '',
      ).toJson();
      expect(json.containsKey('fcmToken'), isFalse);
    });

    test('carries the params through unchanged', () {
      final json = GoogleSignInRequestModel.fromParams(
        const GoogleSignInParams(idToken: 'tok', fcmToken: 'fcm'),
      ).toJson();
      expect(json['idToken'], 'tok');
      expect(json['fcmToken'], 'fcm');
    });
  });

  group('AuthRemoteDataSource.googleSignIn', () {
    test('POSTs the ID token to /auth/google and reads the token back', () async {
      final (:source, :http) = _setup({
        'POST /auth/google': (200, {
          'success': true,
          'data': {
            'accessToken': 'rest-token',
            'user': {'_id': 'u1', 'name': 'Aisha', 'email': 'a@example.com'},
          },
        }),
      });

      final result = await source.googleSignIn(
        const GoogleSignInRequestModel(idToken: 'google-jwt'),
      );

      expect(http.last.path, '/auth/google');
      expect(http.last.method, 'POST');
      expect((http.last.data as Map)['idToken'], 'google-jwt');
      expect(result.token, 'rest-token');
      expect(result.user?.email, 'a@example.com');
    });

    test('reads the token from the Authorization header when the body omits it',
        () async {
      final http = _StubAdapter({});
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test/api/v1',
          validateStatus: (s) => s != null && s < 500,
        ),
      )..httpClientAdapter = _HeaderTokenAdapter();

      final source = AuthRemoteDataSourceImpl(dio: dio);
      final result = await source.googleSignIn(
        const GoogleSignInRequestModel(idToken: 'google-jwt'),
      );
      expect(result.token, 'header-token');
      expect(http.requests, isEmpty);
    });

    test('a rejected token surfaces the server message', () async {
      final (:source, :http) = _setup({
        'POST /auth/google': (401, {
          'success': false,
          'message': 'Invalid Google token',
        }),
      });

      expect(
        () => source.googleSignIn(
          const GoogleSignInRequestModel(idToken: 'bad'),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid Google token'),
          ),
        ),
      );
    });
  });

  group('AccountRepositoryImpl.googleSignIn', () {
    test('caches the token under the same key as an e-mail sign-in', () async {
      final (:source, :http) = _setup({
        'POST /auth/google': (200, {
          'success': true,
          'data': {
            'accessToken': 'rest-token',
            'user': {'_id': 'u1', 'name': 'Aisha', 'email': 'a@example.com'},
          },
        }),
      });
      final local = _FakeLocal();
      final repo = AccountRepositoryImpl(source, local: local);

      final result = await repo.googleSignIn(
        const GoogleSignInParams(idToken: 'google-jwt'),
      );

      expect(result.isRight(), isTrue);
      expect(local.token, 'rest-token');
      expect(repo.isSignedIn, isTrue);
      expect(result.getOrElse(() => throw 'no user').email, 'a@example.com');
    });

    test('falls back to the Google profile when the API returns no user',
        () async {
      final (:source, :http) = _setup({
        'POST /auth/google': (200, {
          'success': true,
          'data': {'accessToken': 'rest-token'},
        }),
      });
      final repo = AccountRepositoryImpl(source, local: _FakeLocal());

      final result = await repo.googleSignIn(
        const GoogleSignInParams(
          idToken: 'google-jwt',
          email: 'a@example.com',
          displayName: 'Aisha',
        ),
      );

      final user = result.getOrElse(() => throw 'no user');
      expect(user.name, 'Aisha');
      expect(user.email, 'a@example.com');
    });

    test('a failure leaves no token behind', () async {
      final (:source, :http) = _setup({
        'POST /auth/google': (401, {
          'success': false,
          'message': 'Invalid Google token',
        }),
      });
      final local = _FakeLocal();
      final repo = AccountRepositoryImpl(source, local: local);

      final result = await repo.googleSignIn(
        const GoogleSignInParams(idToken: 'bad'),
      );

      expect(result.isLeft(), isTrue);
      expect(local.token, isNull);
      expect(repo.isSignedIn, isFalse);
    });
  });

  group('GoogleSignInUser', () {
    test('rejects an empty ID token before any request is made', () async {
      final (:source, :http) = _setup({});
      final usecase = GoogleSignInUser(
        AccountRepositoryImpl(source, local: _FakeLocal()),
      );

      final result = await usecase(const GoogleSignInParams(idToken: '   '));

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) {});
      // Nothing reached the network.
      expect(http.requests, isEmpty);
    });
  });

  group('GoogleAuthConfig', () {
    test('reports unconfigured while the server client ID is blank', () {
      // Guards the UI: the Google buttons stay hidden until a web OAuth
      // client ID is supplied, rather than failing when tapped.
      expect(
        GoogleAuthConfig.isConfigured,
        GoogleAuthConfig.serverClientId.isNotEmpty,
      );
    });

    test('the Android client ID is the one registered in the Cloud project', () {
      expect(
        GoogleAuthConfig.androidClientId,
        endsWith('.apps.googleusercontent.com'),
      );
    });
  });
}

/// Answers with the token in the `Authorization` header and an empty body,
/// which is how some deployments return the session.
class _HeaderTokenAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': <String, dynamic>{}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'authorization': ['Bearer header-token'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
