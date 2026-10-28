import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/device_identity_service.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/services/google_auth_config.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/google_sign_in_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/repositories/account_repository_impl.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DeviceIdentityService.instance.resetForTest();
  });

  group('GoogleSignInRequestModel', () {
    test('always sends the ID token and platform', () {
      final json = const GoogleSignInRequestModel(idToken: 'tok').toJson();
      expect(json['idToken'], 'tok');
      expect(json['platform'], isNotEmpty);
      // Absent values are left out rather than sent as null/empty.
      expect(json.containsKey('fcmToken'), isFalse);
      expect(json.containsKey('deviceId'), isFalse);
      expect(json.containsKey('appVersion'), isFalse);
    });

    test('sends the full body the backend documents', () {
      final json = const GoogleSignInRequestModel(
        idToken: 'tok',
        fcmToken: 'fcm',
        deviceId: 'dev-1',
        appVersion: '1.0.8+8',
      ).toJson();
      expect(json, {
        'idToken': 'tok',
        'platform': json['platform'],
        'fcmToken': 'fcm',
        'deviceId': 'dev-1',
        'appVersion': '1.0.8+8',
      });
    });

    test('an empty deviceId or appVersion is left out', () {
      final json = const GoogleSignInRequestModel(
        idToken: 'tok',
        deviceId: '',
        appVersion: '',
      ).toJson();
      expect(json.containsKey('deviceId'), isFalse);
      expect(json.containsKey('appVersion'), isFalse);
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
        const GoogleSignInParams(
          idToken: 'tok',
          fcmToken: 'fcm',
          deviceId: 'dev-1',
          appVersion: '1.0.8+8',
        ),
      ).toJson();
      expect(json['idToken'], 'tok');
      expect(json['fcmToken'], 'fcm');
      expect(json['deviceId'], 'dev-1');
      expect(json['appVersion'], '1.0.8+8');
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

    test('sends deviceId and appVersion in the request body', () async {
      final (:source, :http) = _setup({
        'POST /auth/google': (200, {
          'success': true,
          'data': {'accessToken': 'rest-token'},
        }),
      });
      final repo = AccountRepositoryImpl(source, local: _FakeLocal());

      await repo.googleSignIn(
        const GoogleSignInParams(
          idToken: 'google-jwt',
          fcmToken: 'fcm',
          deviceId: 'dev-1',
          appVersion: '1.0.8+8',
        ),
      );

      final body = http.last.data as Map;
      expect(body['idToken'], 'google-jwt');
      expect(body['fcmToken'], 'fcm');
      expect(body['deviceId'], 'dev-1');
      expect(body['appVersion'], '1.0.8+8');
      expect(body['platform'], isNotEmpty);
    });

    test('fills in the device identity when the caller supplies none', () async {
      final (:source, :http) = _setup({
        'POST /auth/google': (200, {
          'success': true,
          'data': {'accessToken': 'rest-token'},
        }),
      });
      final repo = AccountRepositoryImpl(source, local: _FakeLocal());

      await repo.googleSignIn(const GoogleSignInParams(idToken: 'google-jwt'));

      final body = http.last.data as Map;
      // The generated ID is always available; appVersion needs the platform
      // channel, which a unit test does not have, so it is simply omitted.
      expect(body['deviceId'], isNotEmpty);
      expect(body['platform'], isNotEmpty);
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

  group('DeviceIdentityService', () {
    test('generates an ID once and reuses it afterwards', () async {
      final first = await DeviceIdentityService.instance.deviceId();
      expect(first, isNotNull);
      expect(first, isNotEmpty);

      // A fresh read of the same store returns the same value, so the backend
      // sees one stable device across launches.
      DeviceIdentityService.instance.resetForTest();
      final second = await DeviceIdentityService.instance.deviceId();
      expect(second, first);
    });

    test('a different install gets a different ID', () async {
      final first = await DeviceIdentityService.instance.deviceId();

      SharedPreferences.setMockInitialValues({});
      DeviceIdentityService.instance.resetForTest();
      final other = await DeviceIdentityService.instance.deviceId();

      expect(other, isNot(first));
    });
  });

  group('request logging', () {
    test('redacts the ID token and other credentials', () {
      final logged = debugRedactLogData({
        'idToken': 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk0M2Ez',
        'fcmToken': 'f6jziqmgSkmIkpOzxqcRrY:APA91bG3',
        'platform': 'android',
        'deviceId': '8b77c50e-1e58-428a-8e55-80ad8f1d5b3f',
      });

      final text = logged.toString();
      expect(text, isNot(contains('eyJhbGciOiJSUzI1NiI')));
      expect(text, isNot(contains('APA91bG3')));
      expect(text, contains('<redacted'));
      // Non-secret fields stay readable, or debugging becomes impossible.
      expect((logged as Map)['platform'], 'android');
      expect(logged['deviceId'], '8b77c50e-1e58-428a-8e55-80ad8f1d5b3f');
    });

    test('redacts a session token in a nested response body', () {
      final logged = debugRedactLogData({
        'success': true,
        'data': {'accessToken': 'secret-session-jwt', 'user': {'name': 'A'}},
      }) as Map;

      expect(logged.toString(), isNot(contains('secret-session-jwt')));
      expect((logged['data'] as Map)['user'], {'name': 'A'});
    });
  });

  group('GoogleAuthConfig', () {
    test('the web server client ID is set, so sign-in is configured', () {
      // Without this the Android Credential Manager issues no ID token at
      // all, and every sign-in fails with a configuration error.
      expect(GoogleAuthConfig.isConfigured, isTrue);
      expect(
        GoogleAuthConfig.serverClientId,
        endsWith('.apps.googleusercontent.com'),
      );
      // The token's `aud` is this value, and the backend verifies against it,
      // so it must belong to our own Cloud project.
      expect(GoogleAuthConfig.serverClientId, startsWith('104828246708-'));
    });

    test('the server and Android client IDs are different clients', () {
      // A common mistake is pasting the Android client ID as serverClientId;
      // Google then refuses to mint a token.
      expect(
        GoogleAuthConfig.serverClientId,
        isNot(GoogleAuthConfig.androidClientId),
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
