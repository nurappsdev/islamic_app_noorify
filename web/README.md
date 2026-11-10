# Web configuration

The Android Firebase application cannot be reused as a browser Firebase
application. In Firebase Console, add a **Web app** to the existing
`tuhfatulmuslim-3bb03` project and copy its configuration values.

Run locally with the values from that Web app:

```sh
flutter run -d chrome \
  --dart-define=FIREBASE_WEB_API_KEY=... \
  --dart-define=FIREBASE_WEB_APP_ID=... \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=104828246708 \
  --dart-define=FIREBASE_WEB_PROJECT_ID=tuhfatulmuslim-3bb03 \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=tuhfatulmuslim-3bb03.firebaseapp.com \
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET=tuhfatulmuslim-3bb03.firebasestorage.app
```

Use the same defines for `flutter build web --release`. Do not commit API
secrets: Firebase's public Web config is safe to publish, but OAuth client
secrets and Facebook app secrets must stay on the backend.

Before login works, add `localhost` and every deployed domain under Firebase
Authentication → Settings → Authorized domains. In Google Cloud, configure the
same domains as JavaScript origins and redirect URIs for the Web OAuth client.
For Facebook Login, add the deployed HTTPS URL as a Valid OAuth Redirect URI
and permitted domain in the Facebook app dashboard. Also enable **Login with
the JavaScript SDK** and set an active Meta Graph SDK version at build time if
the default is no longer supported:

```sh
--dart-define=FACEBOOK_WEB_SDK_VERSION=v<your-active-version>
```

The REST backend must return CORS headers for the deployed origin (including
`Authorization`, `Content-Type`, and the methods used by the app). Browser
requests cannot bypass a missing CORS policy.

See [`docs/web-backend-cors.md`](../docs/web-backend-cors.md) for the exact
origins, methods, and headers this project requires.
