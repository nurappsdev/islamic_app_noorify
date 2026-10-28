# Handoff: `POST /auth/google` for the Node.js backend

Everything the backend needs to support Google Sign-In in the Android app.
The Flutter side is already built and calls this endpoint; nothing on the
client needs to change once this ships.

**Status as of 2026-10-28:** the route does not exist on production. Verified
against `https://api.tuhfatulmuslim.com/api/v1`: `/auth/login` answers
`401 Missing credentials` and `/auth/register` answers `400 Zod Error`, while
`/auth/google` (and 24 other path spellings) answer
`404 {"success":false,"message":"API not found"}`.

If you prefer a different path, that is fine — tell us the final one and we
change a single constant (`ApiConstants.googleSignInEndPoint`).

---

## 1. What you need from the Google Cloud side

| Item | Value |
|---|---|
| Google Cloud project | `tuhfatulmuslim-3bb03` (project number `104828246708`) |
| **Web OAuth client ID** | *to be created — see note below* |
| Web OAuth client **secret** | **not needed for this endpoint** (see §4) |
| Android package name | `com.tuhfatulmuslim.app` |

The **Web** OAuth client ID is the value the ID token is issued for, so it is
what you verify `aud` against. It is the *same* value the Android app is
configured with — not a separate backend-only credential. Once it is created,
it will look like:

```
104828246708-xxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

Put it in the backend environment as `GOOGLE_WEB_CLIENT_ID`.

---

## 2. Request

```
POST /api/v1/auth/google
Content-Type: application/json
X-API-Key: <the same key every other endpoint already requires>
```

```jsonc
{
  "idToken": "<Google ID token — a JWT>",
  "platform": "android",             // always sent
  "fcmToken": "<this device's push token>",
  "deviceId": "<stable per-install UUID>",
  "appVersion": "1.0.8+8"            // "<version>+<buildNumber>"
}
```

`idToken` and `platform` are always present. The other three are omitted
entirely (not sent as `null` or `""`) when the device cannot supply them —
e.g. `fcmToken` before notification permission is granted — so **treat them
as optional** and do not make them required in the Zod schema.

`deviceId` is a random UUID generated on first launch and kept in the app's
local storage. It identifies the *install*, not the hardware: it survives
sign-out and app restarts, and changes on reinstall. Android's hardware IDs
are deliberately not used (`Build.ID` is not unique, and `ANDROID_ID` is no
longer exposed to apps).

**Trust nothing but `idToken`** — the e-mail, name and picture must be read
out of the verified token, never from the request body. `deviceId` and
`appVersion` are client-supplied and unverified, so use them for telemetry
and device bookkeeping, never for authorization.

## 3. Response — identical envelope to `/auth/login`

```jsonc
{
  "success": true,
  "message": "Logged in",
  "data": {
    "accessToken": "<your normal app JWT>",
    "user": { "_id": "...", "name": "...", "email": "..." }
  }
}
```

Set the refresh-token cookie exactly as `/auth/login` does.

The client is tolerant: it also accepts the token as `token`, `access_token`
or `jwt`, or in an `Authorization` / `x-access-token` response header, and it
copes with `user` being absent. Errors are read from `message` or
`errorSources[].message`, same as everywhere else.

---

## 4. Verifying the ID token

```sh
npm i google-auth-library
```

```js
const { OAuth2Client } = require('google-auth-library');

// No client secret needed: verifying an ID token only requires the audience.
const client = new OAuth2Client(process.env.GOOGLE_WEB_CLIENT_ID);

async function verifyGoogleIdToken(idToken) {
  const ticket = await client.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_WEB_CLIENT_ID,
  });

  const payload = ticket.getPayload();

  // verifyIdToken already checks the signature, `exp` and `aud`.
  // These two are still on us:
  const issuers = ['accounts.google.com', 'https://accounts.google.com'];
  if (!issuers.includes(payload.iss)) {
    throw new Error('Bad token issuer');
  }
  if (payload.email_verified !== true) {
    throw new Error('Google account e-mail is not verified');
  }

  return {
    googleId: payload.sub,       // stable, never reused — the real identity
    email: payload.email,
    name: payload.name,
    picture: payload.picture,
  };
}
```

Do **not** decode the JWT without verifying it, and do not call
`tokeninfo` per request — `verifyIdToken` caches Google's public keys for you.

## 5. Account linking rules

This is the part that protects the existing users, so it matters most.

1. Look the user up by **`payload.email`**.
2. **Account exists** → set `googleId = payload.sub` on it if not already set,
   then sign them in. This is what lets someone who registered with
   e-mail + password also use the Google button, with the same account and the
   same data.
3. **No account** → create one with the e-mail already marked verified and
   **no password**. Make sure the rest of the system tolerates a passwordless
   user — in particular `POST /auth/delete-account`, which verifies a password
   before deletion, and `/settings/change-password`.
4. **Conflict guard** → if the account's stored `googleId` is set and differs
   from `payload.sub`, reject rather than overwrite.
5. Register `fcmToken` when supplied, exactly as `/auth/login` does.

## 6. Suggested error responses

| Case | Status | `message` |
|---|---|---|
| `idToken` missing/empty | 400 | `idToken is required` |
| signature/`aud`/`exp` invalid | 401 | `Invalid Google token` |
| `email_verified` is false | 403 | `Google account e-mail is not verified` |
| account disabled | 403 | the existing disabled-account message |

The app surfaces `message` to the user as-is, so keep it human-readable.

## 7. How to test it

```sh
curl -X POST https://api.tuhfatulmuslim.com/api/v1/auth/google \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: <api key>' \
  -d '{"idToken":"<a real ID token from the Android app>"}'
```

A real token is easy to capture: run the app with the Google button, sign in,
and log `result.idToken` in `GoogleAuthService.signIn()`. Tokens expire after
about an hour.
