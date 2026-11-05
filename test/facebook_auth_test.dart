import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/services/device_identity_service.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/services/facebook_auth_config.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/facebook_sign_in_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/repositories/account_repository_impl.dart';
import 'package:tuhfatul_muslim/features/auth/domain/usecases/facebook_sign_in_user.dart';

/// Answers each request by path and remembers what was sent.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.routes);

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

  group('FacebookAuthConfig', () {
    test('ships the App ID the native SDK is configured with', () {
      // Must stay in step with facebook_app_id in strings.xml.
      expect(FacebookAuthConfig.appId, '1693801695699739');
      expect(FacebookAuthConfig.isConfigured, isTrue);
    });

    test('asks only for permissions that need no App Review', () {
      expect(FacebookAuthConfig.loginPermissions, ['email', 'public_profile']);
    });
  });

  group('FacebookSignInRequestModel', () {
    test('always sends the access token and platform', () {
      final json = const FacebookSignInRequestModel(
        accessToken: 'tok',
      ).toJson();
      expect(json['accessToken'], 'tok');
      expect(json['platform'], isNotEmpty);
      // Absent values are left out rather than sent as null/empty.
      expect(json.containsKey('fcmToken'), isFalse);
      expect(json.containsKey('deviceId'), isFalse);
      expect(json.containsKey('appVersion'), isFalse);
    });

    test('sends the full body the backend documents', () {
      final json = const FacebookSignInRequestModel(
        accessToken: 'tok',
        fcmToken: 'fcm',
        deviceId: 'dev-1',
        appVersion: '1.0.8+9',
      ).toJson();
      expect(json, {
        'accessToken': 'tok',
        'platform': json['platform'],
        'fcmToken': 'fcm',
        'deviceId': 'dev-1',
        'appVersion': '1.0.8+9',
      });
    });

    test('empty optional values are left out rather than sent blank', () {
      final json = const FacebookSignInRequestModel(
        accessToken: 'tok',
        fcmToken: '',
        deviceId: '',
        appVersion: '',
      ).toJson();
      expect(json.containsKey('fcmToken'), isFalse);
      expect(json.containsKey('deviceId'), isFalse);
      expect(json.containsKey('appVersion'), isFalse);
    });

    test('carries the params through unchanged', () {
      final json = FacebookSignInRequestModel.fromParams(
        const FacebookSignInParams(
          accessToken: 'tok',
          fcmToken: 'fcm',
          deviceId: 'dev-1',
          appVersion: '1.0.8+9',
        ),
      ).toJson();
      expect(json['accessToken'], 'tok');
      expect(json['fcmToken'], 'fcm');
      expect(json['deviceId'], 'dev-1');
      expect(json['appVersion'], '1.0.8+9');
    });
  });

  group('AuthRemoteDataSource.facebookSignIn', () {
    test(
      'POSTs the token to /auth/facebook and reads the session back',
      () async {
        final (:source, :http) = _setup({
          'POST /auth/facebook': (
            200,
            {
              'success': true,
              'data': {
                'accessToken': 'rest-token',
                'user': {
                  '_id': 'u1',
                  'name': 'Aisha',
                  'email': 'a@example.com',
                },
              },
            },
          ),
        });

        final result = await source.facebookSignIn(
          const FacebookSignInRequestModel(accessToken: 'fb-token'),
        );

        expect(http.last.path, '/auth/facebook');
        expect(http.last.method, 'POST');
        expect((http.last.data as Map)['accessToken'], 'fb-token');
        expect(result.token, 'rest-token');
        expect(result.user?.email, 'a@example.com');
      },
    );

    test('a rejected token surfaces the server message', () async {
      final (:source, :http) = _setup({
        'POST /auth/facebook': (
          401,
          {'success': false, 'message': 'Invalid Facebook token'},
        ),
      });

      expect(
        () => source.facebookSignIn(
          const FacebookSignInRequestModel(accessToken: 'bad'),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid Facebook token'),
          ),
        ),
      );
    });
  });

  group('AccountRepositoryImpl.facebookSignIn', () {
    test('caches the token under the same key as an e-mail sign-in', () async {
      final (:source, :http) = _setup({
        'POST /auth/facebook': (
          200,
          {
            'success': true,
            'data': {
              'accessToken': 'rest-token',
              'user': {'_id': 'u1', 'name': 'Aisha', 'email': 'a@example.com'},
            },
          },
        ),
      });
      final local = _FakeLocal();
      final repo = AccountRepositoryImpl(source, local: local);

      final result = await repo.facebookSignIn(
        const FacebookSignInParams(accessToken: 'fb-token'),
      );

      expect(result.isRight(), isTrue);
      expect(local.token, 'rest-token');
      expect(repo.isSignedIn, isTrue);
      expect(result.getOrElse(() => throw 'no user').email, 'a@example.com');
    });

    test(
      'falls back to the Facebook profile when the API returns no user',
      () async {
        final (:source, :http) = _setup({
          'POST /auth/facebook': (
            200,
            {
              'success': true,
              'data': {'accessToken': 'rest-token'},
            },
          ),
        });
        final repo = AccountRepositoryImpl(source, local: _FakeLocal());

        final result = await repo.facebookSignIn(
          const FacebookSignInParams(
            accessToken: 'fb-token',
            email: 'a@example.com',
            displayName: 'Aisha',
          ),
        );

        final user = result.getOrElse(() => throw 'no user');
        expect(user.name, 'Aisha');
        expect(user.email, 'a@example.com');
      },
    );

    test('a login with no e-mail still yields a session', () async {
      // `email` is a declinable Facebook permission, so this is a normal
      // successful login, not an error.
      final (:source, :http) = _setup({
        'POST /auth/facebook': (
          200,
          {
            'success': true,
            'data': {'accessToken': 'rest-token'},
          },
        ),
      });
      final local = _FakeLocal();
      final repo = AccountRepositoryImpl(source, local: local);

      final result = await repo.facebookSignIn(
        const FacebookSignInParams(
          accessToken: 'fb-token',
          displayName: 'Aisha',
        ),
      );

      expect(result.isRight(), isTrue);
      expect(local.token, 'rest-token');
      expect(result.getOrElse(() => throw 'no user').name, 'Aisha');
    });

    test('fills deviceId and appVersion from the device services', () async {
      final (:source, :http) = _setup({
        'POST /auth/facebook': (
          200,
          {
            'success': true,
            'data': {'accessToken': 'rest-token'},
          },
        ),
      });
      final repo = AccountRepositoryImpl(source, local: _FakeLocal());

      await repo.facebookSignIn(
        const FacebookSignInParams(
          accessToken: 'fb-token',
          fcmToken: 'fcm',
          deviceId: 'dev-1',
          appVersion: '1.0.8+9',
        ),
      );

      final body = http.last.data as Map;
      expect(body['accessToken'], 'fb-token');
      expect(body['fcmToken'], 'fcm');
      expect(body['deviceId'], 'dev-1');
      expect(body['appVersion'], '1.0.8+9');
      expect(body['platform'], isNotEmpty);
    });

    test('a rejected token leaves no session behind', () async {
      final (:source, :http) = _setup({
        'POST /auth/facebook': (
          401,
          {'success': false, 'message': 'Invalid Facebook token'},
        ),
      });
      final local = _FakeLocal();
      final repo = AccountRepositoryImpl(source, local: local);

      final result = await repo.facebookSignIn(
        const FacebookSignInParams(accessToken: 'bad'),
      );

      expect(result.isLeft(), isTrue);
      expect(local.token, isNull);
      expect(repo.isSignedIn, isFalse);
    });
  });

  group('FacebookSignInUser', () {
    test('an empty access token never reaches the network', () async {
      final (:source, :http) = _setup({});
      final repo = AccountRepositoryImpl(source, local: _FakeLocal());

      final result = await FacebookSignInUser(repo)(
        const FacebookSignInParams(accessToken: '   '),
      );

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(http.requests, isEmpty);
    });
  });
}
