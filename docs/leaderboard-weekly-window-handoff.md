# Handoff: the `weekly` window of `GET /leaderboard/top` for the Node.js backend

The weekly leaderboard aggregates the **wrong seven days**. The window has to
be the *trailing* seven days ending today, not the calendar week that contains
today. The client now asks for that window explicitly (§4); the server still
has to honour it, and should resolve a bare `period=weekly` the same way (§2).

**Reported 2026-11-23.** On that date (a Monday) the weekly board came back as:

```jsonc
"period": { "type": "weekly", "key": "2026-W48", "label": "Week 48, 2026",
            "from": "2026-11-23", "to": "2026-11-29" }
```

(verbatim from a debug run of the app against production)

Six of those seven days had not happened yet, so the "weekly" board was really
a daily board: it could only hold Monday's points. The window we need for the
same date is:

```jsonc
"period": { "type": "weekly", "from": "2026-11-17", "to": "2026-11-23", … }
```

---

## 1. What the client sends, and what it does with the answer

The weekly request, as the app sends it today:

```
GET /api/v1/leaderboard/top?period=weekly&limit=10&from=2026-11-17&to=2026-11-23
Authorization: Bearer <token>
X-API-Key: <the same key every other endpoint requires>
```

- `lib/core/services/api_constants.dart:90` — the path.
- `lib/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart`
  — the query parameters: `period`, `limit`, and `from`/`to` for weekly (§4).
- `lib/features/leaderboard/data/models/leaderboard_board_model.dart:18-19` —
  `period.from`, `period.to`, `period.key` and `period.label` are **parsed from
  your response**. Apart from the `from`/`to` it now sends, the
  client does no date arithmetic on the result, so it cannot correct a window
  the server computed differently.

`period.label` is printed to the user as-is on the user-detail screen
(`leaderboard_user_detail_screen.dart:160`), so whatever it says is what they
read.

The same applies to `GET /leaderboard/users/:userId?period=weekly` — it must
resolve `weekly` to the identical window, or a user's standing will disagree
with the board they tapped it from.

## 2. The rule we need

For `period=weekly`, in the app's timezone (`Asia/Dhaka`):

| Field | Value |
|---|---|
| `to` | today |
| `from` | today − 6 days |
| days aggregated | the 7 calendar days `from … to`, inclusive |

Expressed in code:

```js
// Asia/Dhaka, the timezone every other date in this API already uses.
const to   = startOfDay(nowInDhaka());
const from = subDays(to, 6);          // 7 days inclusive, never a future day
```

**No day after today may ever be inside the window.** That is the actual
defect: a window that runs into the future makes the board look empty or
frozen for most of the week, worst of all on the day the week rolls over.

Worked examples:

| Today | `from` | `to` |
|---|---|---|
| 2026-11-23 (Mon) | 2026-11-17 | 2026-11-23 |
| 2026-11-24 (Tue) | 2026-11-18 | 2026-11-24 |
| 2026-11-29 (Sun) | 2026-11-23 | 2026-11-29 |
| 2026-12-01 (Tue) | 2026-11-25 | 2026-12-01 |

The window slides by one day every day; it does not jump on Mondays.

## 3. `key` and `label`

`key` is the string the client sends back as `date` when it opens one user's
standing from a board (`leaderboard_remote_data_source.dart:67`), so it has to
round-trip: given that `key`, the server must rebuild the *same* seven days.
A calendar-week key such as `2026-W48` can no longer identify a sliding
window — please make the weekly key the window's end date:

```jsonc
"key": "2026-11-23"        // == period.to
```

and have `GET /leaderboard/top?period=weekly&date=2026-11-23` (and the
per-user endpoint) resolve to `2026-11-17 … 2026-11-23`. Older keys in the
`2026-W48` shape should keep resolving to something sane rather than 500,
since a client may still hold one.

`label` is shown to the user, so it should name the range, not the week
number — e.g. `17 Nov – 23 Nov 2026`. Bengali digits are applied by the client
(`context.localizedDigits`), so send Western digits.

## 4. `from` / `to`: the client already sends them

**Updated 2026-11-23.** The app now sends an explicit window with the weekly
filter, so the request arriving at your end is:

```
GET /leaderboard/top?period=weekly&limit=10&from=2026-11-17&to=2026-11-23
```

`from` is the earlier day, `to` is today, both `YYYY-MM-DD`, seven days
inclusive. They are sent **only** for `weekly`; `daily`, `monthly` and
`yearly` still send `period` alone and keep your window.

Please honour them: aggregate exactly `from … to` and echo the same two dates
back in `period.from` / `period.to`. Rules we rely on — `to` defaults to
today, `from` defaults to the §2 rule, `from > to` or a future `to` is a
`400`, and `period.from`/`period.to` always state what was actually
aggregated.

Honouring these parameters is enough on its own to fix the user-visible bug,
and it is the smaller change of the two. §2 is still worth doing so that a
plain `period=weekly` (anything else calling this API) is also right.

The client logs a warning when the answer's window differs from the one it
asked for, so an ignored parameter is visible immediately in a debug run.

## 5. How to verify

```bash
curl -s -H "Authorization: Bearer <token>" -H "X-API-Key: <key>" \
  "https://api.tuhfatulmuslim.com/api/v1/leaderboard/top?period=weekly&limit=3" \
  | jq '.data.period'
```

Expected on 2026-11-23:

```json
{ "type": "weekly", "key": "2026-11-23", "label": "17 Nov – 23 Nov 2026",
  "from": "2026-11-17", "to": "2026-11-23" }
```

Checks worth keeping:

- `to` equals today in `Asia/Dhaka`, on every day of the week.
- `from` equals `to` − 6 days.
- Totals change when yesterday's points change, and a day that falls out of
  the window stops counting the next day.
- `daily`, `monthly` and `yearly` are untouched by this change.
- The board and `GET /leaderboard/users/:userId?period=weekly` report the same
  `from`/`to` and agree on a given user's points.

## 6. Please confirm back

1. `weekly` is now the trailing 7 days ending today, in `Asia/Dhaka`.
2. The weekly `key` is the window's end date and round-trips through `date=`.
3. Whether `from`/`to` query parameters are accepted (§4).
