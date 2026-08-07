# Backend changes — Phase 1 demo review

Companion to `SalesHub_API_Documentation.md`. Tracks what the Flutter client
needs from the Python/FastAPI side, and what the client does in the meantime.

**Status: all seven items from the demo review have shipped.** The doc revision
dated after the review adds `dashboard.view`, `period=custom`,
`summary.num_accounts`, stage names on the stage-history and export sheets,
`account_name`/`owner_name`/`stage_name` on `DealRead`,
`POST /users/{id}/activate` and a repeatable `tier`. What follows records how
the client consumes each, plus the two things still outstanding.

| # | Change | Status | Client |
|---|---|---|---|
| 1 | `period=custom` + `start_date`/`end_date` on `GET /dashboard` | shipped | Custom range picker sends it |
| 2 | `summary.num_accounts` | shipped | "No. of Accounts" tile; hidden if the key is absent |
| 3 | Stage **names** in stage-history + exports | shipped | Timeline prefers them over the catalog |
| 4 | `account_name`/`owner_name`/`stage_name` on `DealRead` | shipped | Used directly; the id→name fan-out is now skipped |
| 5 | `POST /users/{id}/activate` | shipped | Activate action on deactivated users |
| 6 | Repeatable `tier` on deals list/export | shipped | Whole tier checkbox selection is exported |
| 7 | `dashboard.view` permission | shipped | Nav entry + route gated; see the warning below |
| — | `leaderboard[].owner_avatar_url` | **not shipped** | Falls back to a `GET /users` lookup |
| — | Lost deals in "Deals Closed" | **open question** | See below |

---

## Shipped — notes on how the client consumes each

### `dashboard.view` — read this before deploying

`GET /dashboard` is no longer permission-free, so **Sales Rep and Delivery SME
now get `403` on what used to be the app's landing page.** The client handles it:
the Dashboard nav entry is hidden without the code, the `/` route is gated, and
redirects walk to the first module the user *can* open (leads → deals → accounts
→ contacts → settings → their profile). Without that walk the old
"bounce to `/`" behaviour would have been an infinite redirect loop.

Two things to confirm on your side:
- **Every existing role needs its permission set reviewed**, not just the
  starter four. A role created through `/roles` before this change has no
  `dashboard.view`, so those users lose the dashboard silently on deploy.
- The login response's `permissions` array must include `dashboard.view` —
  the client gates on the login payload, not on a `/permissions` call.

### `DealRead` display names

This was the root cause of the empty Kanban card. The client previously joined
`account_id`/`owner_id`/`stage_id` against `GET /accounts?limit=1000`,
`GET /users` and `/deal-stages` — and `GET /accounts` is itself row-scoped, so a
rep looking at their own deal on a **colleague's account** got no match and the
card rendered with a blank account line.

The client now reads the wire values and only falls back to those lookups when a
field comes back empty, which also removes two requests per board render. Please
keep these fields on every route that returns a `DealRead` (list, board, detail,
create, update, and the account/contact deal lists) — a route that omits them
silently reintroduces the fan-out.

### Stage names and `changed_by_name`

The deal timeline now reads "**Priya Shah** moved this deal from **Evaluation**
to **Proposals**", taking `from_stage_name`/`to_stage_name`/`changed_by_name`
straight from `GET /deals/{id}/stage-history`. `changed_by_name` still has a
client-side fallback (resolved from `GET /users` by `changed_by`) for older
builds; it's skipped whenever the payload supplies the name.

### Notifications

The read/unread action routes were replaced by `PATCH /notifications/{id}` with
`{"is_read": …}`. The client called the old `/{id}/read` and `/{id}/unread`
paths, so **the read/unread toggle was broken against the current server** until
this client change — worth a regression check on your side too.

### Repeatable `tier`

The export now sends the whole checkbox selection (`?tier=gold&tier=silver`).
Previously it could only send a tier when exactly one box was ticked, so a
two-tier selection exported unfiltered — the spreadsheet disagreed with the
screen.

---

## Still open

### 1. `leaderboard[].owner_avatar_url`

The only demo-review item without a server-side field. Add the rep's
`User.avatar_url` to each leaderboard entry:

```json
{ "owner_id": 12, "owner_name": "Sarah Jenks", "owner_avatar_url": "/media/avatars/12.png", "revenue": 124000.0, "deals_closed": 9 }
```

Relative `/media/...` path exactly as `UserRead.avatar_url` returns it, `null`
when the user has no photo.

**Workaround in place:** `DashboardBloc` fetches `GET /users` once and matches on
`owner_id`, so avatars already appear — but only for callers holding
`users.view`. It switches itself off as soon as the payload carries the field,
so shipping it needs no client release.

### 2. "Lost deals to be added to Deals Closed" — needs a decision

The review sheet asks for lost deals to count in the dashboard's **Deals
Closed** tile. The API doc states the opposite: *"Deals closed is **Closed Won
only** (Closed Lost deals never count here)"*.

These can't both hold, and it changes what the number means — "deals we won" vs
"deals that reached a terminal stage". Worth deciding explicitly, because the
tile's `change_pct` and the leaderboard both key off the same won-revenue
definition:

- **If Deals Closed should mean won + lost**, the cleanest shape is to keep
  `deals_closed` as-is and add a sibling (`deals_lost`, same
  `{value, change_pct}`), letting the tile show "42 won · 9 lost". No existing
  consumer changes meaning.
- **If it should be a single combined count**, say so and the client will
  relabel the tile — but the leaderboard must stay won-only, or revenue ranking
  becomes meaningless.

The client currently renders whatever `deals_closed` contains, so no client
change is needed until this is settled.

---

## Later (not started)

- **S3 for static content.** Avatars and documents are served from a local
  `/media` mount. Moving to S3 changes `avatar_url`/`file_url` to absolute URLs —
  the client already passes anything starting with `http` straight through
  (`resolveMediaUrl`), so this is backend-only. Note the client appends a `?v=`
  cache-buster to avatars because their path is derived from the user id;
  content-addressed S3 keys would make that unnecessary.
- **Favourite lead.** The API side has landed (`is_favourite` on `POST /leads`,
  favourites sorted first in `GET /leads`, and an auto-logged activity with a
  null `type`). The client doesn't use it yet: it needs a star control on the
  list/detail rows, and the activity timeline needs to render a
  null-`type` entry without falling through to its default icon.
- **Contacts import.** `GET /contacts/import/template` and
  `POST /contacts/import` exist; the client only wires the equivalents for
  leads so far.
- **Forgot/reset password.** `POST /auth/forgot-password` and
  `/auth/reset-password` exist server-side, but the client's Forgot Password
  screen is a **stub**: pressing "send" only flips a local flag and shows the
  success view — no request is made, so no email is ever sent. There is also no
  reset-password screen for the emailed token to land on. Worth scheduling; a
  user today is told to check an inbox that will stay empty.
