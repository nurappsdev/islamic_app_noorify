# Google Sign-In (without Firebase Authentication)

The app signs in with Google through **Google Identity Services** only. Firebase
Authentication is not involved: the device obtains a Google **ID token** and
posts it to our own REST backend, which verifies it and returns the usual app
session token. Firebase stays in the project for messaging and everything else
it already did.

```
 device                      Google                      our backend
   │  authenticate()            │                              │
   ├───────────────────────────►│                              │
   │  ◄── ID token (JWT) ───────┤                              │
   │                                                            │
   ├──────── POST /auth/google { idToken, fcmToken } ──────────►│
   │                                            verify with Google's JWKS
   │  ◄──────── { success, data: { accessToken, user } } ───────┤
   │  token cached in Hive under `auth_token` — same key as e-mail login
```

Because the token lands in the same Hive key as an e-mail sign-in, every
protected request, the refresh interceptor, guest mode and logout keep working
unchanged, and a Google session is indistinguishable from any other.

---

## 1. Google Cloud state

Project `tuhfatulmuslim-3bb03`, project number `104828246708`.

| Client | Status |
|---|---|
| Android OAuth client `104828246708-sbspq2oe1jbq834bv88ubd1ojkg17kvm` | exists — registered against SHA-1 `d13cf662…a985b8` (the Google Play App Signing key) |
| **Web ("server") OAuth client** | **missing — must be created** |
| **iOS OAuth client** (`com.tuhfatulmuslim.app`) | **missing — must be created** |

### SHA-1 fingerprints

| Key | SHA-1 | Registered on the Firebase app |
|---|---|---|
| Play App Signing | `D1:3C:F6:62:9B:2B:AF:FC:A7:40:C9:66:6C:7E:99:55:38:A9:85:B8` | yes (pre-existing) |
| Debug (`~/.android/debug.keystore`) | `6F:2B:69:DC:CE:B1:06:6C:D7:AA:5F:61:47:0C:13:D7:84:A2:D4:AB` | yes (added) |
| Upload (`android/app/upload-keystore.jks`, alias `upload`) | `84:9E:E8:BC:EB:9C:92:13:56:31:80:84:47:AA:74:CA:28:17:4A:D8` | yes (added) |

Re-read them at any time with:

```sh
# debug
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore \
  -storepass android -keypass android | grep SHA1

# upload (reads the password out of android/key.properties)
cd android && keytool -list -v -alias upload -keystore app/upload-keystore.jks | grep SHA1
```

The **Play App Signing** SHA-1 is the one that matters in production, because
Google Play re-signs every release with it. Read it from
**Play Console → your app → Test and release → Setup → App signing**. The value
already registered (`D1:3C:F6:62:…`) is almost certainly it — confirm it matches
before shipping.

---

## 1b. Android-only quick start (current scope)

iOS is deliberately out of scope for now. To get the button live on Android,
only **two** console steps are needed, then one line of config:

1. Create the **Web** OAuth client (2.2) — required even on Android.
2. Create an **Android** OAuth client for the debug SHA-1 (2.3), so you can
   test locally. Production is already covered by the Play App Signing client.
3. Paste the web client ID into `GoogleAuthConfig._defaultServerClientId`.

The button is hidden until step 3, then appears on Sign-In, Sign-Up and the
guest prompt. Nothing else in the app changes.

## 2. Manual steps (these cannot be automated)

Google exposes **no CLI or API for creating OAuth 2.0 client IDs**. `gcloud` has
only `gcloud iap oauth-clients`, which is IAP-specific and was shut down in
March 2026, and the Firebase MCP/CLI can add SHA-1 fingerprints but does not
mint OAuth clients (it only does that when the Google provider is turned on in
Firebase Authentication, which this app deliberately does not use). So the
following are console-only.

### 2.1 OAuth consent screen / branding

**APIs & Services → OAuth consent screen** — confirm the app name, support
e-mail, logo, the authorised domain `tuhfatulmuslim.com`, and the privacy-policy
and terms URLs. The `email`, `profile` and `openid` scopes are all this flow
needs, and they are non-sensitive, so **no Google verification review is
required**. Publish the app (rather than leaving it in Testing) or only accounts
on the test-user list can sign in.

### 2.2 Create the Web ("server") OAuth client — required

**APIs & Services → Credentials → Create credentials → OAuth client ID →
Web application**. Name it e.g. "Tuhfatul Muslim backend". No redirect URI is
needed for this flow.

This client is required on **every** platform, not just the web: it is the
`aud` the ID token is minted for, and Android's Credential Manager refuses to
issue a token without it.

Then put its ID into `lib/core/services/google_auth_config.dart`
(`_defaultServerClientId`), or pass it per build:

```sh
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=104828246708-xxxx.apps.googleusercontent.com
```

Until this is set, `GoogleAuthConfig.isConfigured` is `false` and the Google
buttons stay hidden, so nothing can fail at tap time.

> The web client also has a **client secret**. It belongs on the backend only.
> Never put it in this repo.

### 2.3 Create Android OAuth clients for the debug and upload keys

The existing Android client only covers the Play App Signing certificate, so
locally-built debug and release APKs will fail with `DEVELOPER_ERROR` /
`clientConfigurationError` until each signing certificate has its own client.

**Credentials → Create credentials → OAuth client ID → Android**, twice:

| Package name | SHA-1 |
|---|---|
| `com.tuhfatulmuslim.app` | `6F:2B:69:DC:CE:B1:06:6C:D7:AA:5F:61:47:0C:13:D7:84:A2:D4:AB` (debug) |
| `com.tuhfatulmuslim.app` | `84:9E:E8:BC:EB:9C:92:13:56:31:80:84:47:AA:74:CA:28:17:4A:D8` (upload) |

Nothing needs pasting into the app for these — the Android SDK matches them by
package name + signature at runtime.

### 2.4 Create the iOS OAuth client — deferred, not needed for Android

**Credentials → Create credentials → OAuth client ID → iOS**, bundle ID
`com.tuhfatulmuslim.app`.

Then:

1. Put the client ID into `GoogleAuthConfig._defaultIosClientId`, or pass
   `--dart-define=GOOGLE_IOS_CLIENT_ID=...`.
2. Uncomment the `CFBundleURLTypes` block in `ios/Runner/Info.plist` and set the
   scheme to the **reversed** client ID
   (`com.googleusercontent.apps.104828246708-xxxx`). The block is already there
   with instructions.

> Separately, iOS has no `GoogleService-Info.plist` and `firebase_options.dart`
> throws for iOS, so **Firebase itself is not configured for iOS at all**. That
> is pre-existing and unrelated to Google Sign-In (which reads its client ID
> from `GoogleAuthConfig`), but push notifications will not work on iOS until
> it is addressed.

---

## 3. Backend contract

`POST {baseUrl}/auth/google` — **not deployed as of 2026-10-28.** Every path
variant on `https://api.tuhfatulmuslim.com/api/v1` returns
`404 {"success": false, "message": "API not found"}`, while known routes such as
`/auth/login` return `401 Missing credentials`, so the 404 is a genuinely
missing route rather than a rejected request.

### Request

```jsonc
{
  "idToken": "<Google ID token (JWT)>",
  "fcmToken": "<optional, device push token>",
  "platform": "android" | "ios"   // only sent alongside fcmToken
}
```

### Response — identical envelope to `/auth/login`

```jsonc
{
  "success": true,
  "message": "Logged in",
  "data": {
    "accessToken": "<app JWT>",
    "user": { "_id": "...", "name": "...", "email": "..." }
  }
}
```

The client also accepts the token as `token` / `access_token` / `jwt`, or in an
`Authorization` / `x-access-token` response header, and tolerates a missing
`user` object. Errors are read from `message` or `errorSources[].message`, the
same as every other endpoint.

### What the server must do

1. **Verify the ID token** against Google's public keys — do not decode it
   unverified. With `google-auth-library`:

   ```js
   const { OAuth2Client } = require('google-auth-library');
   const client = new OAuth2Client(process.env.GOOGLE_WEB_CLIENT_ID);

   const ticket = await client.verifyIdToken({
     idToken: req.body.idToken,
     audience: process.env.GOOGLE_WEB_CLIENT_ID, // the web client from 2.2
   });
   const payload = ticket.getPayload();
   ```

   `verifyIdToken` already checks the signature, `exp` and `aud`. Additionally
   require `payload.iss` to be `accounts.google.com` or
   `https://accounts.google.com`, and reject the request when
   `payload.email_verified` is not `true`.

2. **Trust only the token.** Take the e-mail, name, picture and `sub` from
   `payload`, never from the request body.

3. **Link, don't duplicate.** Look the user up by `payload.email`. If an account
   exists, attach `googleId = payload.sub` to it and sign them in — this is what
   keeps existing e-mail/password accounts working. If none exists, create one
   with the e-mail already verified and no password. Guard against an account
   whose `googleId` is set to a *different* `sub`.

4. **Issue the same session** as `/auth/login`: the same access token, the same
   refresh-token cookie, the same shape.

5. **Register the FCM token** when one is supplied, as `/auth/login` does.

---

## 4. Where the code lives

| File | Role |
|---|---|
| `lib/core/services/google_auth_config.dart` | the OAuth client IDs + the `isConfigured` guard |
| `lib/features/auth/data/services/google_auth_service.dart` | the Google SDK wrapper; returns an ID token, no Firebase Auth |
| `lib/features/auth/domain/entities/google_sign_in_params.dart` | the value object |
| `lib/features/auth/data/models/google_sign_in_request_model.dart` | the request body |
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | `googleSignIn()` — the HTTP call |
| `lib/features/auth/data/repositories/account_repository_impl.dart` | caches the token; also signs out of Google on logout |
| `lib/features/auth/domain/usecases/google_sign_in_user.dart` | the use case |
| `lib/features/auth/presentation/bloc/login/login_bloc.dart` | `GoogleLoginSubmitted` |
| `lib/features/auth/presentation/screens/signin_screen.dart` | "Continue with Google" button |
| `lib/features/auth/presentation/screens/signup_screen.dart` | the Google button in the social section |
| `lib/core/widgets/login_required_dialog.dart` | the Google button on the guest prompt |
| `test/google_auth_test.dart` | the tests |

## 5. Checklist

**Android (now):**

- [ ] Create the Web OAuth client (2.2) and paste the ID into `GoogleAuthConfig`
- [ ] Create Android OAuth clients for the debug and upload SHA-1s (2.3)
- [ ] Review and publish the OAuth consent screen (2.1)
- [ ] Confirm the Play App Signing SHA-1 in Play Console matches `D1:3C:F6:62:…`
- [ ] Deploy `POST /auth/google` (section 3)

**iOS (deferred):**

- [ ] Create the iOS OAuth client, set the ID, uncomment the URL scheme (2.4)
