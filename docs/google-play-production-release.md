# Google Play production release checklist

This document records the items that must be completed outside the Android
repository before a production submission. They cannot be satisfied merely by
building the app.

## Account deletion

The app exposes an in-app deletion action in **Settings → Delete account**.
The backend endpoint `DELETE /delete/me` must authenticate the bearer token,
delete the account and all user-associated records (including profile details,
avatars/uploads, reading and activity data, prayer/alarm preferences, device
and FCM registrations, refresh tokens, and any server-side backups according
to the published retention schedule), then revoke the session.

Google Play also requires a public web page that users can open without the
app. Before release, deploy a page on the verified developer web domain, for
example `https://tuhfatulmuslim.com/account-deletion`, and enter that exact
HTTPS URL in Play Console. It must:

1. identify Tuhfatul Muslim and the Android package `com.tuhfatulmuslim.app`;
2. give an authenticated route to submit the request (or a support form that
   verifies ownership without collecting a password by email);
3. cover Google, Facebook and email/password accounts equally;
4. state which data is deleted, any legally required retention, and the
   maximum completion period; and
5. link to the current privacy policy and support contact.

Do not publish a placeholder URL. Verify the live page in an incognito browser
and retain a screenshot/test request before entering it in Play Console.

## Data Safety and privacy policy

The Data Safety form must describe both this app and its backend/SDKs, not just
the Android manifest. Confirm the final answers with the backend, Firebase and
Meta owners. The current source indicates these data categories should be
reviewed for declaration:

| Data category | Source/use to confirm | Likely purpose |
| --- | --- | --- |
| Approximate location | Prayer time and Qiblah calculations; coordinates are sent to the prayer-time provider when location is selected | App functionality |
| Name, email address, phone, gender, date of birth, profession, user-entered location, avatar | Account profile and support | Account management / app functionality |
| User IDs, device ID and FCM token | Backend session/device registration and push delivery | Account management / app functionality |
| Religious reading, quiz, plan, bookmark and Zikr progress | Feature state, synchronisation and personalisation | App functionality / personalisation |
| Diagnostics and push data | Firebase Crashlytics/Analytics/Messaging or other enabled SDKs, if enabled in the released build | Confirm actual SDK collection and purpose |

For every category, document whether it is collected, shared, encrypted in
transit, required or optional, and whether users can request deletion. Update
the publicly hosted privacy policy to match those answers, identify Firebase,
Meta/Facebook, Google sign-in and every other processor, and describe the
deletion process above. The in-app policy screen loads a backend document; make
sure it resolves to the same current public policy URL and remains available.

## Play Console declarations

Complete or re-confirm these entries before submission:

- Data Safety and the public Privacy Policy URL.
- Account-deletion URL.
- **Foreground service** declaration for `mediaPlayback`, with the requested
  demonstration video showing user-initiated Quran audio continuing with its
  visible media notification. Do not declare location foreground service.
- Permissions declaration if Play Console requests it for precise location:
  this version declares only `ACCESS_COARSE_LOCATION`, requested from an
  explicit user action. It has no contacts, SMS/call-log, all-files,
  accessibility, local-network or AppFunctions permission/use.
- Ads declaration: the app does not use the advertising ID or Privacy Sandbox
  advertising permissions. Facebook is used for login only; automatic app
  events and advertiser-ID collection are disabled.
- Trader status (required by the announced November 2026 Console change) and,
  if applicable, the Japan payments authorization.

## Release build and API credentials

`API_CLIENT_KEY` is intentionally not stored in source. Build only with a
scoped public client identifier when the current backend still requires that
header:

```sh
flutter build appbundle --release --dart-define=API_CLIENT_KEY=<public-client-id>
```

An identifier embedded in a mobile app is recoverable and must never be treated
as a secret. Rotate the previous hard-coded key, move authorization to the
bearer session, validate provider tokens on the server, rate-limit anonymous
endpoints, and restrict Firebase/Google keys in their respective consoles by
package name and Play App Signing SHA-256 certificate.

## Final verification

1. Inspect the **release** merged manifest/APK, not only debug, and confirm it
   contains no fine/background location, advertising ID, AdServices or
   `USE_EXACT_ALARM` permission.
2. Test email, Google and Facebook deletion against production/staging. Confirm
   each removes backend data and invalidates future authenticated calls.
3. Test email reset; Google/Facebook users should recover through their
   provider and are not shown the app password/reset options when their profile
   identifies them as social users.
4. Test approximate-location prayer times/Qiblah after explicitly choosing to
   use device location, denial recovery, notifications, exact-alarm settings,
   reboot alarm restoration, and background Quran playback.
