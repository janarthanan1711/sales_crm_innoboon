# Backend changes required — Phase 1 demo review

Companion to `SalesHub_API_Documentation.md`, which has been updated to describe
the **target** contract. This file lists what the Python/FastAPI side still has
to build for the Flutter client to work as intended, and what the client does in
the meantime.

## How the "deployed today" claims here were checked

Every statement about the current API was read from the live OpenAPI document of
the deployment the client points at by default
(`https://sales-prospecting-crm-api.onrender.com/api/v1`, see
`lib/app/di/injector.dart`) on 2026-08-04 — not from documentation. Anything
marked **deployed: no** is absent from that spec.

| # | Change | Deployed | Client today |
|---|---|---|---|
| 1 | `period=custom` + `start_date`/`end_date` on `GET /dashboard` | no | sends it; the request fails until this ships |
| 2 | `summary.num_accounts` | no | tile hidden while the field is absent |
| 3 | `leaderboard[].owner_avatar_url` | no | falls back to `GET /users` lookup |
| 4 | Stage **names** in stage-history + exports | no | resolves from `/deal-stages`, else `Stage <id>` |
| 5 | `account_name`/`owner_name`/`stage_name` on `DealRead` | no | resolves client-side; blanks when the lookup can't see the record |
| 6 | `POST /users/{id}/activate` | **no — and the UI already calls it** | Activate action 404s |
| 7 | Repeatable `tier` on deals list/export | no | multi-tier selections are not applied to the export |

---

## 1. Dashboard period filter — drop `today`, add `custom`

`GET /api/v1/dashboard`

- `period` enum becomes `this_week | this_month | custom` (default `this_month`).
  **Remove `today`** — a single day is now `period=custom` with
  `start_date == end_date`, which is strictly more general.
- Add `start_date` and `end_date` (`YYYY-MM-DD`). Both are **required when
  `period=custom`** and should `422` otherwise; ignore them for the named
  periods. Reject `end_date < start_date`.
- Treat the range as **inclusive of both endpoints** — the client sends whole
  dates, so an exclusive `end_date` silently drops the last day.
- Every section must honour the window (summary, funnel, deal_distribution,
  leaderboard, drop_off_reasons, conversion_trend, activity_feed). The client
  now presents one filter for the whole page, so a section that ignores it reads
  as a bug.
- `granularity` stays independent of `period` — the client picks it from the
  span (≤21 days → `daily`, ≤120 → `weekly`, else `monthly`; `this_week` →
  `daily`, `this_month` → `weekly`) so the trend line always has more than one
  bucket.
- `change_pct` compares against the immediately preceding window **of equal
  length** — for a custom range that's the same number of days ending the day
  before `start_date`.

Until this ships the client's "Custom" segment produces a failed request; the
error text tells the user the API doesn't accept `period=custom` yet.

## 2. `summary.num_accounts`

Add a fifth stat to `summary`, same `{value, change_pct}` shape as its siblings:

```json
"num_accounts": { "value": 96, "change_pct": 5.0 }
```

Accounts **created** in the period (`Account.created_at`), row-scoped the same
way as the rest of the dashboard. The client renders it as a "No. of Accounts"
tile and **omits the tile entirely while the key is missing** — so shipping this
needs no client release, but note that means a genuine zero must be sent as
`{"value": 0, ...}`, never by omitting the key.

## 3. `leaderboard[].owner_avatar_url`

Add the rep's `User.avatar_url` to each leaderboard entry:

```json
{ "owner_id": 12, "owner_name": "Sarah Jenks", "owner_avatar_url": "/media/avatars/12.png", "revenue": 124000.0, "deals_closed": 9 }
```

Relative `/media/...` path exactly as `UserRead.avatar_url` returns it, or `null`
when the user has no photo. It's a join the client can't do cheaply.

**Workaround in place:** `DashboardBloc` fetches `GET /users` once and matches on
`owner_id`, so avatars already appear for callers holding `users.view`. That
lookup is skipped as soon as the payload carries `owner_avatar_url`, so no client
change is needed when this ships — but the workaround does nothing for a role
without `users.view`, which is why the field is still wanted.

## 4. Stage names, not stage ids

Three places surface a bare stage id today:

1. **`GET /deals/{id}/stage-history`** — add `from_stage_name` and
   `to_stage_name` (and `changed_by_name`, already documented). The client
   currently resolves names from the `/deal-stages` catalog, which cannot
   recover the name of a **deleted** stage — the timeline then reads "Stage
   moved from Stage 3 to Stage 4".
2. **Single-deal export** (`GET /deals/{id}?to_export=true`) — the "Stage
   History" sheet writes `From Stage ID`/`To Stage ID`; write the names.
3. **Account and contact exports** — the "Deals" sheet writes `Stage ID`; write
   the name. (The deals *list* export already writes the name — these two are
   inconsistent with it.)

The client reads `from_stage_name`/`to_stage_name` when present and falls back to
the catalog, so it will pick these up with no release.

## 5. `DealRead` should carry its display names — root cause of the empty Kanban card

`DealRead` is `{id, deal_name, account_id, contacts, value, currency,
expected_close_date, stage_id, tier, cold_reason, owner_id}` — **no
`account_name`, `owner_name`, or `stage_name`.** The client therefore fans out to
`GET /accounts?limit=1000`, `GET /users` and `GET /deal-stages` and joins by id.

That join is what produces the "empty" Kanban card, and it explains the
"sometimes":

- A **Sales Rep** (no `accounts.view_all`) sees only their *own* accounts from
  `GET /accounts`. A deal they own on a **colleague's account** finds no match →
  the account line renders blank.
- Same for `GET /users` without `users.view`, and for `/deal-stages` if that
  request fails → the stage chip renders blank.
- `GET /accounts?limit=1000` also truncates silently past 1000 accounts.

So the card degrades to little more than a value and a date — nothing to read,
nothing that identifies the deal.

**Ask:** return `account_name`, `owner_name` and `stage_name` (plus
`stage_is_cold`) on `DealRead`. It removes three N+1 lookups per board render and
makes the card correct regardless of the caller's row scope.

**Client-side mitigations already shipped** (they make the card readable, but the
data is still missing): every line falls back to a visible placeholder —
`Untitled deal #12` / `No account linked` / `Unassigned` / `Stage 4` — and deals
whose `stage_id` matches no known stage now appear in a trailing "Unknown stage"
column instead of vanishing from the board.

## 6. `POST /users/{id}/activate` — **missing, and already called**

The hot-fix branch added an "Activate" row action for deactivated users
(`ActivateUserUseCase` → `POST /api/v1/users/{id}/activate`). **That route does
not exist on the deployed API** — `/api/v1/users/{user_id}` only has `delete`.
Clicking Activate returns the same "Resource not found" that the original
Deactivate-on-a-deactivated-user bug produced.

Please add:

| | |
|---|---|
| Endpoint | `/api/v1/users/{user_id}/activate` |
| Method | `POST` |
| Permission | `users.manage` |
| Response | `204 No Content` (or `UserRead`) |

Semantics: clear the soft-delete, set `is_active = true` and `status = active`.
Idempotent on an already-active user. `404` when the user doesn't exist.

(`POST /users` already reactivates a soft-deleted user *by email* and reissues a
password — that is a different operation and shouldn't be used as the Activate
button, since it resets the password.)

## 7. Deals export: allow more than one `tier`

`GET /deals?to_export=true` takes a single `tier`. The UI's tier filter is a set
of four checkboxes, so the export can only honour it when **exactly one** box is
ticked — pick two and the spreadsheet contains rows the screen is hiding.

Make `tier` repeatable (`?tier=gold&tier=silver`, as `types` already is on the
activity endpoints) on both `GET /deals` and its export, and the client will send
the full selection.

---

## Later (not started — listed so they aren't lost)

- **Dashboard visibility permission.** `GET /dashboard` is currently open to any
  authenticated user. Adding e.g. `dashboard.view` means the client must hide the
  nav entry and route-guard `/dashboard`; the guard map already exists in
  `lib/app/router/app_router.dart`, so this is a small change on both sides.
- **S3 for static content.** Avatars and documents are served from a local
  `/media` mount. Moving to S3 changes `avatar_url`/`file_url` to absolute URLs —
  the client already handles absolute URLs (`resolveMediaUrl` passes anything
  starting with `http` straight through), so this is backend-only. Note the
  client appends a `?v=` cache-buster to avatars because their path is derived
  from the user id; content-addressed S3 keys would make that unnecessary.
- **Favourite lead.** Needs a per-user flag (`lead_favourites(user_id, lead_id)`,
  not a column on `leads`), a toggle endpoint, and `is_favourite` on `LeadRead`
  plus a `favourites_only` list filter.
