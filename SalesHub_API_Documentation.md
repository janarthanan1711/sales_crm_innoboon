# SalesHub API Documentation

For the UI/frontend team. Covers every live HTTP endpoint in the SalesHub backend.

**Base URL:** all endpoints are prefixed with `/api/v1` (e.g. `/api/v1/leads`).

**Auth:** JWT Bearer access token, obtained from `POST /auth/login`. Send on every
request (except `login`/`refresh`, which are public):
```
Authorization: Bearer <access_token>
```
Routes with a **Permission Required** also need the caller's role to hold that
permission code — otherwise `403`. Routes marked "any authenticated user" just
need a valid, non-expired, non-revoked token — `401` otherwise.

**Standard paginated list envelope:**
```json
{ "items": [ /* ... */ ], "total": 42, "limit": 20, "offset": 0 }
```

**Standard error envelope** (unhandled/structured errors):
```json
{ "status_code": 400, "status": "error", "message": "human-readable message" }
```
Some routes raise plain FastAPI `HTTPException`s, which return `{"detail": "..."}` instead — noted per-endpoint where relevant.

**Permission catalog** (`GET /permissions`, 14 codes): `users.manage`, `users.view`,
`roles.manage`, `leads.access`, `leads.view_all`, `leads.notify_on_create`,
`leads.delete_any_activity`, `accounts.access`, `accounts.view_all`,
`accounts.delete_any_activity`, `deals.access`, `deals.view_all`,
`deals.delete_any_activity`, `contacts.access`, `audit_log.view`.

Starter roles: **Admin** (all permissions) · **Sales Manager** (access + view_all
on leads/accounts/deals, contacts.access, users.view) · **Sales Rep** (access-only
on leads/accounts/deals/contacts, users.view) · **Delivery SME** (leads.access,
users.view).

---

## Table of Contents

1. [Auth](#1-auth)
2. [Users](#2-users)
3. [Leads](#3-leads)
4. [Accounts](#4-accounts)
5. [Contacts](#5-contacts)
6. [Deals](#6-deals)
7. [Deal Stages](#7-deal-stages)
8. [Dashboard](#8-dashboard)
9. [Notifications](#9-notifications)
10. [Search](#10-search)
11. [Documents](#11-documents)
12. [Audit Log](#12-audit-log)
13. [Permissions](#13-permissions)
14. [Roles](#14-roles)

---

## 1. Auth

Prefix: `/auth`. Login/refresh are public; logout requires a valid token.

### 1.1. Login
**To** log in and obtain access/refresh tokens.

| | |
|---|---|
| Endpoint | `/api/v1/auth/login` |
| Method | `POST` |
| Header Parameter | None (public) |
| Permission Required | None |
| Params | N/A |

Example Request
```json
{
  "email": "jane.doe@company.com",
  "password": "SecurePass123"
}
```

Example Response
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "8f14e45fceea167a5a36dedd4bea2543...",
  "token_type": "bearer",
  "permissions": ["leads.access", "accounts.access", "deals.access", "contacts.access"]
}
```
Errors: `401` invalid email/password.

### 1.2. Refresh Access Token
**To** exchange a valid refresh token for a new access token.

| | |
|---|---|
| Endpoint | `/api/v1/auth/refresh` |
| Method | `POST` |
| Header Parameter | None (public) |
| Permission Required | None |
| Params | N/A |

Example Request
```json
{ "refresh_token": "8f14e45fceea167a5a36dedd4bea2543..." }
```

Example Response
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...(new)",
  "refresh_token": "8f14e45fceea167a5a36dedd4bea2543...(same, no rotation)",
  "token_type": "bearer"
}
```
Note: `permissions` is omitted on refresh (only returned by login). Errors: `401` invalid/expired/revoked refresh token, or user inactive.

### 1.3. Logout
**To** revoke a refresh token (idempotent).

| | |
|---|---|
| Endpoint | `/api/v1/auth/logout` |
| Method | `POST` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | N/A |

Example Request
```json
{ "refresh_token": "8f14e45fceea167a5a36dedd4bea2543..." }
```

Example Response: `204 No Content`. Returns 204 even for an unknown/foreign refresh token.

---

## 2. Users

Prefix: `/users`.

### 2.1. Create User
**To** create a new user account. Server generates a random password and emails it (best-effort; email failure doesn't fail the request).

| | |
|---|---|
| Endpoint | `/api/v1/users` |
| Method | `POST` |
| Header Parameter | Bearer access token required |
| Permission Required | `users.manage` |
| Params | N/A |

Example Request
```json
{
  "email": "jane.doe@company.com",
  "first_name": "Jane",
  "last_name": "Doe",
  "role_id": 2
}
```

Example Response (`201`)
```json
{
  "id": 12,
  "email": "jane.doe@company.com",
  "first_name": "Jane",
  "last_name": "Doe",
  "phone_number": null,
  "avatar_url": null,
  "role": { "id": 2, "name": "Sales Manager", "description": "Manages leads/accounts/deals", "permissions": [] },
  "is_active": true,
  "status": "invited",
  "created_at": "2026-07-20T09:00:00Z",
  "last_login_at": null
}
```
Errors: `409` email already exists (reactivates a soft-deleted user with the same email instead of failing, reissuing a password) · `404` `role_id` invalid.

### 2.2. Get Current User
**To** fetch the logged-in user's own profile.

| | |
|---|---|
| Endpoint | `/api/v1/users/me` |
| Method | `GET` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | N/A |

Example Response: `UserRead` (see 2.1).

### 2.3. Update Current User
**To** update the logged-in user's own name/phone (email not editable here).

| | |
|---|---|
| Endpoint | `/api/v1/users/me` |
| Method | `PATCH` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | N/A |

Example Request
```json
{ "first_name": "Jane", "last_name": "Doe", "phone_number": "+1-555-0100" }
```
Example Response: `UserRead`.

### 2.4. Change Own Password
**To** change the logged-in user's password. Forces re-login everywhere: revokes every refresh token, and the JWT `iat` claim means even the current access token stops working.

| | |
|---|---|
| Endpoint | `/api/v1/users/me/password` |
| Method | `POST` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | N/A |

Example Request
```json
{ "current_password": "OldPass123", "new_password": "NewPass456" }
```
Example Response: `204 No Content`. `new_password` requires min length 8 plus at least one uppercase, one lowercase, one digit. Errors: `400` current password incorrect.

### 2.5. Upload Avatar
**To** upload/replace the logged-in user's avatar image.

| | |
|---|---|
| Endpoint | `/api/v1/users/me/avatar` |
| Method | `POST` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | `multipart/form-data` field `file` (`image/png` or `image/jpeg` only) |

Example Response: `UserRead` with `avatar_url` set (e.g. `/media/avatars/12.png`, served via the `/media` static mount). Errors: `400` unsupported file type.

### 2.6. Delete Avatar
**To** remove the logged-in user's uploaded avatar (deletes the file on disk and clears `avatar_url`). No-op (still `200`) if no avatar is set.

| | |
|---|---|
| Endpoint | `/api/v1/users/me/avatar` |
| Method | `DELETE` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | N/A |

Example Response: `UserRead` with `avatar_url: null`.

### 2.7. List Users
**To** list users, e.g. for owner-assignment dropdowns.

| | |
|---|---|
| Endpoint | `/api/v1/users` |
| Method | `GET` |
| Header Parameter | Bearer access token required |
| Permission Required | `users.view` |
| Params | `role_id?`, `is_active?`, `status?` (`active`\|`invited`\|`deactivated`), `search?` |

Example Response: `list[UserRead]` (no pagination).

### 2.8. Delete User
**To** soft-delete (deactivate) a user.

| | |
|---|---|
| Endpoint | `/api/v1/users/{user_id}` |
| Method | `DELETE` |
| Header Parameter | Bearer access token required |
| Permission Required | `users.manage` |
| Params | path: `user_id` |

Example Response: `204 No Content`. Errors: `404` user not found.

---

## 3. Leads

Prefix: `/leads`. Every route requires `leads.access`. Without `leads.view_all`, results/access are scoped to leads the caller owns plus unassigned leads (`owner_id IS NULL`, a shared claimable queue).

**Note on route order:** `import/template` and `import` are defined before `/{lead_id}` to avoid path collisions.

**Export:** there is no separate `/export` route. Pass `to_export=true` on `GET /leads` (list, section 3.2) or `GET /leads/{lead_id}` (single record, section 3.6) instead — see those sections for the resulting xlsx shape.

### 3.1. Create or Update Lead
**To** create a new lead, or update an existing one when `id` is included in the body.

| | |
|---|---|
| Endpoint | `/api/v1/leads` |
| Method | `POST` |
| Permission Required | `leads.access` |
| Params | N/A. Create requires `first_name, company, email, source`. Update: include `id` plus any fields to change. |

Example Request (create)
```json
{
  "first_name": "Alex",
  "last_name": "Kim",
  "company": "Acme Corp",
  "domain": "acme.com",
  "job_title": "VP Sales",
  "email": "alex.kim@acme.com",
  "phone": "+1-555-0111",
  "linkedin_url": "https://linkedin.com/in/alexkim",
  "source": "website",
  "status": "not_contacted",
  "owner_id": 12,
  "next_follow_up_date": "2026-08-01",
  "follow_up_note": "Send pricing deck",
  "contacts": [{ "email": "alex.kim@acme.com", "phone": "+1-555-0111" }]
}
```
`source` enum: `website`, `referral`, `cold_call`, `linkedin`, `email_campaign`, `other`.
`status` enum: `not_contacted`, `attempted_to_contact`, `contacted`, `contact_in_future`, `junk_lead`, `lost_lead`.

Example Response (`201` create / `200` update)
```json
{
  "id": 101,
  "first_name": "Alex",
  "last_name": "Kim",
  "company": "Acme Corp",
  "domain": "acme.com",
  "job_title": "VP Sales",
  "email": "alex.kim@acme.com",
  "phone": "+1-555-0111",
  "linkedin_url": "https://linkedin.com/in/alexkim",
  "source": "website",
  "status": "not_contacted",
  "owner_id": 12,
  "owner_name": "Jane Doe",
  "next_follow_up_date": "2026-08-01",
  "follow_up_note": "Send pricing deck",
  "is_converted": false,
  "updated_at": "2026-07-01T10:00:00Z"
}
```
Errors: `404` lead not found (update) · `403` not owner and lacks `leads.view_all` · `409` duplicate lead email.

### 3.2. List Leads
**To** list/search leads (paginated).

| | |
|---|---|
| Endpoint | `/api/v1/leads` |
| Method | `GET` |
| Permission Required | `leads.access` |
| Params | `owner_id?, source?, status?, search?, limit=20, offset=0, to_export=false` |

Example Response
```json
{ "items": [ { "...": "LeadRead" } ], "total": 1, "limit": 20, "offset": 0 }
```

**`to_export=true`:** ignores `limit`/`offset`, returns every role-scoped lead matching `owner_id`/`source`/`status`/`search` (excludes already-converted leads, same as the normal list) as an `xlsx` file stream (`Content-Disposition: attachment; filename=leads.xlsx`) instead of the JSON envelope above. Single sheet "Leads", columns: Name, Email, Phone, Company, Source, Status, Owner.

### 3.3. Lead Import Template
**To** download an empty import template for leads.

| | |
|---|---|
| Endpoint | `/api/v1/leads/import/template` |
| Method | `GET` |
| Permission Required | `leads.access` |
| Params | `format=xlsx\|csv` |

Response: file download (xlsx or csv).

### 3.4. Import Leads
**To** bulk-create leads from a spreadsheet.

| | |
|---|---|
| Endpoint | `/api/v1/leads/import` |
| Method | `POST` |
| Permission Required | `leads.access` |
| Params | `multipart/form-data` field `file` (`.xlsx` or `.csv`) |

Example Response
```json
{
  "created": 18,
  "errors": [ { "row": 5, "error": "email is required" } ]
}
```
Errors: `400` unreadable file/bad format.

### 3.5. Get Lead Detail
**To** fetch full lead detail including contacts and activity history.

| | |
|---|---|
| Endpoint | `/api/v1/leads/{lead_id}` |
| Method | `GET` |
| Permission Required | `leads.access` |
| Params | path: `lead_id`; query: `to_export=false` |

Example Response
```json
{
  "id": 101,
  "first_name": "Alex", "last_name": "Kim", "company": "Acme Corp",
  "owner_id": 12, "owner_name": "Jane Doe",
  "is_converted": false,
  "contacts": [ { "email": "alex.kim@acme.com", "phone": "+1-555-0111" } ],
  "activities": [ { "id": 5, "type": "note", "note": "Called, left voicemail", "created_by": 12, "created_by_name": "Jane Doe", "created_at": "2026-07-05T12:00:00Z" } ],
  "activity_count": 1,
  "last_contact_at": "2026-07-05T12:00:00Z"
}
```
Errors: `404` / `403`.

**`to_export=true`:** returns an `xlsx` file stream (`Content-Disposition: attachment; filename="lead_{lead_id}.xlsx"`) instead of the JSON body above. Two sheets: "Lead" (Field/Value pairs — all `LeadDetailRead` scalar fields) and "Activities" (Type, Note, Created By, Created At — one row per logged activity).

### 3.6. Delete Lead
| | |
|---|---|
| Endpoint | `/api/v1/leads/{lead_id}` |
| Method | `DELETE` |
| Permission Required | `leads.access` |
| Params | path: `lead_id` |

Response: `204 No Content`. Errors: `404` / `403`.

### 3.7. Convert Lead to Account
**To** convert a qualified lead into an account.

| | |
|---|---|
| Endpoint | `/api/v1/leads/{lead_id}/convert` |
| Method | `POST` |
| Permission Required | `leads.access` |
| Params | path: `lead_id` |

Example Request (optional body)
```json
{ "tier": "gold", "owner_id": 12 }
```
Example Response (`201`): `AccountRead` (see 4.1). Errors: `404` / `403` · `409` already converted · `400` missing required fields for conversion.

### 3.8. Add Lead Activity
| | |
|---|---|
| Endpoint | `/api/v1/leads/{lead_id}/activities` |
| Method | `POST` |
| Permission Required | `leads.access` |
| Params | path: `lead_id` |

Example Request
```json
{ "type": "call", "note": "Called, left voicemail" }
```
`type` enum: `note`, `meeting`, `call`, `comment`, `follow_up`.

Example Response (`201`)
```json
{ "id": 5, "lead_id": 101, "type": "call", "note": "Called, left voicemail", "created_by": 12, "created_at": "2026-07-05T12:00:00Z", "updated_by": null, "updated_at": null }
```

### 3.9. List Lead Activities
| | |
|---|---|
| Endpoint | `/api/v1/leads/{lead_id}/activities` |
| Method | `GET` |
| Permission Required | `leads.access` |
| Params | path: `lead_id`; query: `types?` (repeatable), `date_from?`, `date_to?` |

Example Response: `list[LeadActivityDetailRead]` (adds `created_by_name`, `updated_by_name`).

### 3.10. Update Lead Activity
| | |
|---|---|
| Endpoint | `/api/v1/leads/{lead_id}/activities/{activity_id}` |
| Method | `PATCH` |
| Permission Required | `leads.access` |
| Params | path: `lead_id, activity_id` |

Example Request
```json
{ "note": "Updated note text" }
```
Errors: `404` lead/activity · `403`.

### 3.11. Delete Lead Activity
| | |
|---|---|
| Endpoint | `/api/v1/leads/{lead_id}/activities/{activity_id}` |
| Method | `DELETE` |
| Permission Required | `leads.access` (delete of another user's activity additionally requires `leads.delete_any_activity`) |
| Params | path: `lead_id, activity_id` |

Response: `204 No Content`. Errors: `404` lead/activity · `403`.

---

## 4. Accounts

Prefix: `/accounts`. Every route requires `accounts.access`. Without `accounts.view_all`, scoped to accounts the caller owns.

### 4.1. Create Account
| | |
|---|---|
| Endpoint | `/api/v1/accounts` |
| Method | `POST` |
| Permission Required | `accounts.access` |
| Params | N/A |

Example Request
```json
{
  "company": "Acme Corp",
  "domain": "acme.com",
  "tier": "gold",
  "owner_id": 12,
  "industry": "Software",
  "city": "San Francisco",
  "description": "Enterprise SaaS provider",
  "linkedin_url": "https://linkedin.com/company/acme",
  "contacts": [ { "first_name": "Alex", "last_name": "Kim", "email": "alex.kim@acme.com", "phone": "+1-555-0111" } ]
}
```
`tier` enum: `diamond`, `gold`, `silver`, `bronze`. `owner_id` is optional — omitted/null defaults to the requesting user. Only the first contact in `contacts` needs a name; later ones just add another email/phone.

Example Response (`201`)
```json
{
  "id": 55, "company": "Acme Corp", "domain": "acme.com", "tier": "gold",
  "owner_id": 12, "owner_name": "Jane Doe", "source_lead_id": null,
  "industry": "Software", "city": "San Francisco",
  "description": "Enterprise SaaS provider",
  "linkedin_url": "https://linkedin.com/company/acme",
  "contact_count": 1, "deal_count": 0
}
```
Errors: `422` first contact missing `first_name`.

### 4.2. List Accounts
| | |
|---|---|
| Endpoint | `/api/v1/accounts` |
| Method | `GET` |
| Permission Required | `accounts.access` |
| Params | `owner_id?, tier?, industry?, search?, limit=20, offset=0, to_export=false` (`search` matches company, domain, or owner name) |

Example Response
```json
{ "items": [ { "...": "AccountRead" } ], "total": 1, "limit": 20, "offset": 0 }
```

**`to_export=true`:** ignores `limit`/`offset`, returns every role-scoped account matching `owner_id`/`tier`/`industry`/`search` as an `xlsx` file stream (`Content-Disposition: attachment; filename=accounts.xlsx`) instead of the JSON envelope above. Single sheet "Accounts", columns: Company, Domain, Tier, Industry, City, Owner.

### 4.3. Get Account
| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}` |
| Method | `GET` |
| Permission Required | `accounts.access` |
| Params | path: `account_id`; query: `to_export=false` |

Response: `AccountRead`. Errors: `404` / `403`.

**`to_export=true`:** returns an `xlsx` file stream (`Content-Disposition: attachment; filename="account_{account_id}.xlsx"`) instead of the JSON body above. Three sheets: "Account" (Field/Value pairs — all `AccountRead` scalar fields), "Contacts" (First Name, Last Name, Email, Phone, Job Title, Primary — one row per linked contact), "Deals" (Deal Name, Value, Currency, Stage ID, Tier, Owner ID, Expected Close Date — one row per deal on this account).

### 4.4. Get Account Overview
**To** power the Account Overview screen in one call.

| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/overview` |
| Method | `GET` |
| Permission Required | `accounts.access` |
| Params | path: `account_id` |

Example Response
```json
{
  "id": 55, "company": "Acme Corp", "tier": "gold",
  "open_deal_value": 125000,
  "key_contacts": [ { "id": 8, "first_name": "Alex", "last_name": "Kim", "email": "alex.kim@acme.com", "is_primary": true } ],
  "active_deals": [ { "id": 33, "deal_name": "Acme Corp - Enterprise Plan", "stage_id": 4, "value": 50000 } ],
  "last_activity": null,
  "next_step": null,
  "total_arr": null
}
```
`open_deal_value` = sum of non-closed/non-cold deal values. `last_activity`/`next_step`/`total_arr` are always `null` — no backing model yet.

### 4.5. Update Account
| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}` |
| Method | `PATCH` |
| Permission Required | `accounts.access` |
| Params | path: `account_id`. Same fields as Create, all optional; `contacts` list appends rather than replaces. |

Example Request
```json
{ "tier": "diamond", "city": "New York" }
```
Response: `AccountRead`. Errors: `404` / `403`.

### 4.6. Delete Account
| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}` |
| Method | `DELETE` |
| Permission Required | `accounts.access` |
| Params | path: `account_id` |

Response: `204 No Content`. Errors: `404` / `403`.

### 4.7. List Account Contacts
**To** list contacts linked to an account (via the `contact_accounts` join table — a contact can belong to more than one account).

| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/contacts` |
| Method | `GET` |
| Permission Required | `accounts.access` |
| Params | path: `account_id`; query: `limit=20, offset=0` |

Example Response
```json
{ "items": [ { "id": 8, "first_name": "Alex", "last_name": "Kim", "email": "alex.kim@acme.com", "phone": "+1-555-0111", "job_title": "VP Sales", "is_primary": true } ], "total": 1, "limit": 20, "offset": 0 }
```

### 4.8. Create or Update Account Contact
**To** add a new contact to an account, or update/re-link an existing contact — same create-or-update dispatch pattern as `POST /leads`.

| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/contacts` |
| Method | `POST` |
| Permission Required | `accounts.access` |
| Params | path: `account_id`. No `contact_id` in body → create (requires `first_name` + `email`, `201`). `contact_id` present → update that contact's fields and/or `is_primary`, creating the link if not already associated with this account (`200`). |

Example Request (create)
```json
{ "first_name": "Alex", "last_name": "Kim", "email": "alex.kim@acme.com", "phone": "+1-555-0111", "job_title": "VP Sales", "is_primary": true }
```
Example Request (update/link existing)
```json
{ "contact_id": 8, "is_primary": true }
```
Example Response
```json
{ "id": 8, "first_name": "Alex", "last_name": "Kim", "email": "alex.kim@acme.com", "phone": "+1-555-0111", "alternate_phone": null, "job_title": "VP Sales", "linkedin_url": null, "is_primary": true }
```
Errors: `404` account/contact not found · `403` · `409` a primary contact already exists for this account (never silently demotes the old primary) · `409` duplicate email (email is globally unique across all contacts).

### 4.9. List Account Deals
| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/deals` |
| Method | `GET` |
| Permission Required | `accounts.access` |
| Params | path: `account_id` |

Response: `list[DealRead]` (see 6). Errors: `404` / `403`.

### 4.10. Add Account Activity
**To** log an activity (note/meeting/call/comment/follow-up) against an account.

| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/activities` |
| Method | `POST` |
| Permission Required | `accounts.access` |
| Params | path: `account_id` |

Example Request
```json
{ "type": "note", "note": "Called to confirm renewal timeline." }
```
`type` enum: `note`, `meeting`, `call`, `comment`, `follow_up`.

Example Response (`201`)
```json
{
  "id": 12, "account_id": 4, "type": "note",
  "note": "Called to confirm renewal timeline.",
  "created_by": 7, "created_at": "2026-07-24T10:15:00Z",
  "updated_by": null, "updated_at": "2026-07-24T10:15:00Z"
}
```

### 4.11. List Account Activities
| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/activities` |
| Method | `GET` |
| Permission Required | `accounts.access` |
| Params | path: `account_id`; query: `types?` (repeat for multiple, e.g. `?types=note&types=call`), `date_from?` (inclusive), `date_to?` (exclusive) |

Example Response (newest-first, includes display names)
```json
[
  {
    "id": 12, "account_id": 4, "type": "note",
    "note": "Called to confirm renewal timeline.",
    "created_by": 7, "created_at": "2026-07-24T10:15:00Z",
    "updated_by": null, "updated_at": "2026-07-24T10:15:00Z",
    "created_by_name": "Priya Nair", "updated_by_name": null
  }
]
```

### 4.12. Update Account Activity
**To** edit an activity. **Only the account's owner can edit** — others get `403`, even with `accounts.view_all`.

| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/activities/{activity_id}` |
| Method | `PATCH` |
| Permission Required | `accounts.access` + must be the account owner |
| Params | path: `account_id, activity_id` |

Example Request (partial)
```json
{ "note": "Updated note text" }
```
Response: same shape as list item. Errors: `404` account/activity · `403` not the account owner.

### 4.13. Delete Account Activity
**Delete is Admin-only** (`accounts.delete_any_activity`) — not even the account owner can delete via this endpoint. (Editing is owner-restricted; deleting is stricter — same convention as Deal and Lead activities.)

| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/activities/{activity_id}` |
| Method | `DELETE` |
| Permission Required | `accounts.delete_any_activity` |
| Params | path: `account_id, activity_id` |

Response: `204 No Content`, empty body.

### 4.14. Upload Account Document
**No separate download/view endpoint** — uploaded files are served from the public static mount at `/media/...`. The response's `file_url` is a relative path (e.g. `/media/account_documents/4_9f2c8a1e....pdf`) — prefix with your API base URL. Use it directly as an `<iframe>`/`<img>`/link `href` to view inline, or `<a href download>` to force save-as.

| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/documents` |
| Method | `POST` |
| Permission Required | `accounts.access` |
| Params | path: `account_id`; `multipart/form-data` field `file` |

Allowed content types: `application/pdf`, `application/msword` (.doc),
`application/vnd.openxmlformats-officedocument.wordprocessingml.document` (.docx),
`image/png`, `image/jpeg`.

Example Response (`201`)
```json
{
  "id": 3, "account_id": 4, "file_name": "MSA_Draft.pdf",
  "file_url": "/media/account_documents/4_9f2c8a1e....pdf",
  "content_type": "application/pdf", "uploaded_by": 7,
  "created_at": "2026-07-24T10:20:00Z"
}
```
Errors: `400` unsupported file type.

### 4.15. List Account Documents
| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/documents` |
| Method | `GET` |
| Permission Required | `accounts.access` |
| Params | path: `account_id` |

Response: `list[AccountDocumentRead]` (same shape as 4.14), newest-first.

### 4.16. Delete Account Document
**To** remove both the DB row and the file on disk. Anyone who can access the account (owner, or `accounts.view_all`) can delete — same rule as deleting the Account record itself.

| | |
|---|---|
| Endpoint | `/api/v1/accounts/{account_id}/documents/{document_id}` |
| Method | `DELETE` |
| Permission Required | `accounts.access` |
| Params | path: `account_id, document_id` |

Response: `204 No Content`, empty body.

---

## 5. Contacts

Prefix: `/contacts`. Every route requires `contacts.access`. A Contact has **no owner_id/tier of its own** — both are derived from the contact's *representative* Account link (its oldest `is_primary=True` link, or its oldest link overall if none is primary; `null` if unlinked). A contact can link to more than one account via the `contact_accounts` join table.

### 5.1. Create Contact
| | |
|---|---|
| Endpoint | `/api/v1/contacts` |
| Method | `POST` |
| Permission Required | `contacts.access` |
| Params | N/A |

Example Request
```json
{
  "first_name": "Alex", "last_name": "Kim",
  "email": "alex.kim@acme.com",
  "phone": "+1-555-0111", "alternate_phone": null,
  "job_title": "VP Sales",
  "linkedin_url": "https://linkedin.com/in/alexkim"
}
```
`email` is required and globally unique.

Example Response (`201`)
```json
{
  "id": 8, "first_name": "Alex", "last_name": "Kim",
  "email": "alex.kim@acme.com", "phone": "+1-555-0111",
  "alternate_phone": null, "job_title": "VP Sales",
  "linkedin_url": "https://linkedin.com/in/alexkim"
}
```
Errors: `409` email already used by another contact · `422` email missing.

### 5.2. List Contacts
**To** power the Contact List screen. Filters match if *any* of a contact's linked accounts satisfies them.

| | |
|---|---|
| Endpoint | `/api/v1/contacts` |
| Method | `GET` |
| Permission Required | `contacts.access` |
| Params | `owner_id?, account_id?, tier?, is_primary?, search?, limit=20, offset=0, to_export=false` |

Example Response
```json
{ "items": [ { "id": 8, "first_name": "Alex", "last_name": "Kim", "email": "alex.kim@acme.com", "owner_id": 12, "tier": "gold", "account_id": 55 } ], "total": 1, "limit": 20, "offset": 0 }
```

**`to_export=true`:** ignores `limit`/`offset`, returns every contact matching `owner_id`/`account_id`/`tier`/`is_primary`/`search` as an `xlsx` file stream (`Content-Disposition: attachment; filename=contacts.xlsx`) instead of the JSON envelope above. Single sheet "Contacts", columns: Name, Email, Phone, Job Title, Account, Owner, Tier, Primary.

### 5.3. Get Contact Overview
**To** power the Contact Detail screen in one call.

| | |
|---|---|
| Endpoint | `/api/v1/contacts/{contact_id}/overview` |
| Method | `GET` |
| Permission Required | `contacts.access` |
| Params | path: `contact_id` |

Example Response
```json
{
  "id": 8, "first_name": "Alex", "last_name": "Kim",
  "email": "alex.kim@acme.com", "job_title": "VP Sales",
  "account_id": 55, "owner_id": 12, "tier": "gold",
  "deal_count": 1,
  "tags": null, "about": null, "last_activity": null,
  "task_count": null, "log_count": null
}
```
`account_id`/`owner_id`/`tier` are `null` if the contact is unlinked. `tags`/`about`/`last_activity`/`task_count`/`log_count` are always `null` — no backing model yet. Errors: `404`.

### 5.4. List Contact Deals
| | |
|---|---|
| Endpoint | `/api/v1/contacts/{contact_id}/deals` |
| Method | `GET` |
| Permission Required | `contacts.access` |
| Params | path: `contact_id` |

Response: `list[DealRead]` (see 6). Errors: `404`.

### 5.5. Get Contact
| | |
|---|---|
| Endpoint | `/api/v1/contacts/{contact_id}` |
| Method | `GET` |
| Permission Required | `contacts.access` |
| Params | path: `contact_id`; query: `to_export=false` |

Response: `ContactRead` (see 5.1). Errors: `404`.

**`to_export=true`:** returns an `xlsx` file stream (`Content-Disposition: attachment; filename="contact_{contact_id}.xlsx"`) instead of the JSON body above. Two sheets: "Contact" (Field/Value pairs — all `ContactRead` scalar fields) and "Deals" (Deal Name, Value, Currency, Stage ID, Tier, Owner ID, Expected Close Date — one row per deal this contact is on).

### 5.6. Update Contact
**Cannot** reassign a contact's account here — use `POST /accounts/{id}/contacts` to (re)link.

| | |
|---|---|
| Endpoint | `/api/v1/contacts/{contact_id}` |
| Method | `PATCH` |
| Permission Required | `contacts.access` |
| Params | path: `contact_id`. All fields optional (same as Create, minus `account_id`). |

Example Request
```json
{ "first_name": "Alex", "job_title": "SVP Sales" }
```
Response: `ContactRead`. Errors: `404` · `409` duplicate email.

### 5.7. Delete Contact
| | |
|---|---|
| Endpoint | `/api/v1/contacts/{contact_id}` |
| Method | `DELETE` |
| Permission Required | `contacts.access` |
| Params | path: `contact_id` |

Response: `204 No Content`. Errors: `404`.

---

## 6. Deals

Prefix: `/deals`. Every route requires `deals.access`. Without `deals.view_all`, scoped to deals the caller owns. Pipeline stages are dynamic (see [Deal Stages](#7-deal-stages)) — `Deal.stage_id`/`DealStageHistory.from_stage_id`/`to_stage_id` reference `deal_stages` rows, not a fixed enum.

**Note on route order:** `/generic-patch` is defined before `/{deal_id}` to avoid path collisions.

**Export:** there is no separate `/export` route. Pass `to_export=true` on `GET /deals` (list, section 6.3) or `GET /deals/{deal_id}` (single record, section 6.4) instead — see those sections for the resulting xlsx shape.

### 6.1. Create Deal
| | |
|---|---|
| Endpoint | `/api/v1/deals` |
| Method | `POST` |
| Permission Required | `deals.access` |
| Params | N/A |

Example Request
```json
{
  "deal_name": "Acme Corp - Enterprise Plan",
  "account_id": 55,
  "contact_ids": [8],
  "value": 50000,
  "currency": "USD",
  "expected_close_date": "2026-09-30",
  "stage_id": 1,
  "tier": "gold",
  "owner_id": 12
}
```
`cold_reason` is required (`400` otherwise) whenever the resulting stage has `is_cold=true`. Creation always writes an initial `DealStageHistory` row (`from_stage_id=null, to_stage_id=stage_id`).

Example Response (`201`)
```json
{
  "id": 33, "deal_name": "Acme Corp - Enterprise Plan", "account_id": 55,
  "value": 50000, "currency": "USD", "expected_close_date": "2026-09-30",
  "stage_id": 1, "tier": "gold", "cold_reason": null, "owner_id": 12,
  "contacts": [ { "id": 8, "name": "Alex Kim", "email": "alex.kim@acme.com", "phone": "+1-555-0111" } ]
}
```
`contact_ids` (request field, still `list[int]`) is write-only — the response returns `contacts`, each with the contact's `id`, display `name`, `email`, and `phone`, so the UI doesn't need a separate contact lookup to render them.

Errors: `404` account/stage/contact not found · `400` `cold_reason` required.

### 6.2. Generic Patch
**Internal/admin ad-hoc field patch — not intended for regular UI forms.** Small allowlisted single-field update across a few tables.

| | |
|---|---|
| Endpoint | `/api/v1/deals/generic-patch` |
| Method | `PATCH` |
| Permission Required | `deals.access` |
| Params | N/A |

Example Request
```json
{ "table": "deals", "record_id": 33, "field": "value", "value": 60000 }
```
`table` allowlist: `deals`, `deal_stage_history`, `deal_stages`.

Example Response
```json
{ "id": 33, "field": "value", "value": 60000 }
```
Errors: `400` table/field not allowlisted · `404` record not found.

### 6.3. List Deals
**To** power both list and Kanban board views of the pipeline.

| | |
|---|---|
| Endpoint | `/api/v1/deals` |
| Method | `GET` |
| Permission Required | `deals.access` |
| Params | `view=list\|board` (default `list`), `owner_id?, account_id?, stage_id?, tier?, search?` (matches deal name + account company name), `sort_by=value\|expected_close_date\|created_at`, `sort_dir=asc\|desc`, `limit=20, offset=0` (list view only), `to_export=false` |

Example Response (`view=list`)
```json
{ "view": "list", "items": [ { "...": "DealRead" } ], "total": 1, "limit": 20, "offset": 0 }
```
Example Response (`view=board`) — groups the same filtered results by stage with per-column totals, unpaginated:
```json
{
  "view": "board",
  "columns": [
    { "stage_id": 1, "stage_name": "Received Requirements", "total_value": 50000, "deals": [ { "...": "DealRead" } ] }
  ]
}
```

**`to_export=true`:** ignores `view`/`limit`/`offset` (always exports the flat list, never the board grouping), returns every role-scoped deal matching `stage_id`/`tier`/`search` as an `xlsx` file stream (`Content-Disposition: attachment; filename=deals.xlsx`) instead of the JSON envelope above. Single sheet "Deals", columns: Deal Name, Account, Contact, Value, Currency, Stage, Tier, Owner, Expected Close Date, Cold Reason.

### 6.4. Get Deal
| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}` |
| Method | `GET` |
| Permission Required | `deals.access` |
| Params | path: `deal_id`; query: `to_export=false` |

Response: `DealRead` (see 6.1). Errors: `404` / `403`.

**`to_export=true`:** returns an `xlsx` file stream (`Content-Disposition: attachment; filename="deal_{deal_id}.xlsx"`) instead of the JSON body above. Two sheets: "Deal" (Field/Value pairs — all `DealRead` scalar fields plus a comma-joined "Contacts" name list) and "Stage History" (From Stage, To Stage, Changed By, Note, Created At — one row per stage transition, stages written as names rather than ids).

### 6.5. Update Deal
`note` is write-only — it populates the resulting `DealStageHistory` row on a stage change, it is not a `Deal` column.

| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}` |
| Method | `PATCH` |
| Permission Required | `deals.access` |
| Params | path: `deal_id`. All fields optional (same as Create, plus `note`). |

Example Request
```json
{ "stage_id": 4, "note": "Sent proposal doc" }
```
Response: `DealRead`. Errors: `404` deal/stage/contact · `403` · `400` `cold_reason` required when moving to a cold stage.

### 6.6. Delete Deal
| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}` |
| Method | `DELETE` |
| Permission Required | `deals.access` |
| Params | path: `deal_id` |

Response: `204 No Content`. Errors: `404` / `403`.

### 6.7. Get Deal Stage History
| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}/stage-history` |
| Method | `GET` |
| Permission Required | `deals.access` |
| Params | path: `deal_id` |

Example Response
```json
[ { "id": 7, "deal_id": 33, "from_stage_id": 1, "from_stage_name": "Received Requirements", "to_stage_id": 4, "to_stage_name": "Proposals", "changed_by": 12, "changed_by_name": "Priya Shah", "note": "Sent proposal doc", "created_at": "2026-07-15T09:00:00Z" } ]
```
`from_stage_name`/`to_stage_name` are resolved server-side so the timeline reads "Stage moved from Received Requirements to Proposals" without a second call — and, unlike a client-side lookup against `/deal-stages`, they still render correctly for a stage that has since been deleted. `from_stage_name` is `null` exactly when `from_stage_id` is (the initial row written at creation). Errors: `404` / `403`.

### 6.8. Add Deal Activity
| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}/activities` |
| Method | `POST` |
| Permission Required | `deals.access` |
| Params | path: `deal_id` |

Example Request
```json
{ "title": "Discovery Call - Architecture Review", "type": "call", "note": "Walked through integration requirements." }
```
`title` is optional. `type` enum: `note`, `meeting`, `call`, `comment`, `follow_up`.

Example Response (`201`)
```json
{ "id": 9, "deal_id": 33, "title": "Discovery Call - Architecture Review", "type": "call", "note": "Walked through integration requirements.", "created_by": 12, "created_at": "2026-07-15T09:10:00Z", "updated_by": null, "updated_at": null }
```

### 6.9. List Deal Activities
| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}/activities` |
| Method | `GET` |
| Permission Required | `deals.access` |
| Params | path: `deal_id`; query: `types?` (repeatable), `date_from?`, `date_to?` |

Response: `list[DealActivityDetailRead]` (adds `created_by_name`/`updated_by_name`).

### 6.10. Update Deal Activity
**Only the deal owner may edit.**

| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}/activities/{activity_id}` |
| Method | `PATCH` |
| Permission Required | `deals.access` + must be the deal owner |
| Params | path: `deal_id, activity_id` |

Example Request
```json
{ "note": "Updated note text" }
```
Errors: `404` deal/activity · `403` not the deal owner.

### 6.11. Delete Deal Activity
**Delete gated by `deals.delete_any_activity`** (Admin only by default) — same pattern as Lead/Account activities.

| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}/activities/{activity_id}` |
| Method | `DELETE` |
| Permission Required | `deals.delete_any_activity` |
| Params | path: `deal_id, activity_id` |

Response: `204 No Content`.

### 6.12. Upload Deal Document
**To** upload a proposal/NDA/contract against a deal. Gated the same way as the Deal record itself (ownership or `deals.view_all`), no extra owner-only rule.

| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}/documents` |
| Method | `POST` |
| Permission Required | `deals.access` |
| Params | path: `deal_id`; `multipart/form-data` field `file` |

Allowed content types: `application/pdf`, `.doc`, `.docx`, `image/png`, `image/jpeg`.

Example Response (`201`)
```json
{
  "id": 6, "deal_id": 33, "file_name": "MSA_Draft.pdf",
  "file_url": "/media/deal_documents/33_ab12cd34....pdf",
  "content_type": "application/pdf", "uploaded_by": 12,
  "created_at": "2026-07-16T09:00:00Z"
}
```
Errors: `404` / `403` · `400` unsupported file type.

### 6.13. List Deal Documents
| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}/documents` |
| Method | `GET` |
| Permission Required | `deals.access` |
| Params | path: `deal_id` |

Response: `list[DealDocumentRead]`, newest-first. Errors: `404` / `403`.

### 6.14. Delete Deal Document
| | |
|---|---|
| Endpoint | `/api/v1/deals/{deal_id}/documents/{document_id}` |
| Method | `DELETE` |
| Permission Required | `deals.access` |
| Params | path: `deal_id, document_id` |

Response: `204 No Content`. Errors: `404` deal/document · `403`.

---

## 7. Deal Stages

Prefix: `/deal-stages`. Every route requires `deals.access` (no separate permission code). Pipeline stages are dynamic, admin-configurable rows grouped per `company_id` (a minimal `companies` table backs this; a single "Default" company is seeded).

### 7.1. Create Deal Stage
| | |
|---|---|
| Endpoint | `/api/v1/deal-stages` |
| Method | `POST` |
| Permission Required | `deals.access` |
| Params | N/A |

Example Request
```json
{ "company_id": 1, "name": "Received Requirements", "sort_order": 1, "is_cold": false }
```

Example Response (`201`)
```json
{ "id": 1, "company_id": 1, "name": "Received Requirements", "sort_order": 1, "is_cold": false }
```

### 7.2. List Deal Stages
| | |
|---|---|
| Endpoint | `/api/v1/deal-stages` |
| Method | `GET` |
| Permission Required | `deals.access` |
| Params | `company_id?` |

Response: `list[DealStageRead]`.

### 7.3. Get Deal Stage
| | |
|---|---|
| Endpoint | `/api/v1/deal-stages/{stage_id}` |
| Method | `GET` |
| Permission Required | `deals.access` |
| Params | path: `stage_id` |

Response: `DealStageRead`. Errors: `404`.

### 7.4. Update Deal Stage
| | |
|---|---|
| Endpoint | `/api/v1/deal-stages/{stage_id}` |
| Method | `PATCH` |
| Permission Required | `deals.access` |
| Params | path: `stage_id` |

Example Request
```json
{ "name": "Proposals", "sort_order": 4, "is_cold": false }
```
`is_cold` on the stage (not a hardcoded stage-name check) drives the cold-reason-required rule on Deals. Response: `DealStageRead`. Errors: `404`.

### 7.5. Delete Deal Stage
| | |
|---|---|
| Endpoint | `/api/v1/deal-stages/{stage_id}` |
| Method | `DELETE` |
| Permission Required | `deals.access` |
| Params | path: `stage_id` |

Response: `204 No Content`. Errors: `404` · `400` stage is still referenced by existing deals.

---

## 8. Dashboard

Prefix: `/dashboard`. **Any authenticated user, no permission code** — read-only aggregation over existing Lead/Deal/DealStage/DealStageHistory/activity data, no dedicated tables. Collapsed into a **single combined endpoint** (no more one-route-per-widget) so the frontend loads the whole dashboard page in one call. Returns zeros/empty lists per section on no data rather than erroring — an empty dashboard is a valid state.

**Not yet built**: Target vs Actual Revenue, the leaderboard's "% of target" figure, and an Upcoming Follow-ups widget. The response below never includes target/quota data.

**Known caveat:** "closed/won/lost" is inferred by matching `DealStage.name` against the fixed Phase 1 stage list (`"Closed Won"`, `"Closed Lost"`) — since `DealStage` is per-company, this breaks silently if a company ever renames those stages. Accepted for Phase 1's fixed stage list.

**Period filter:** the entire page — summary, funnel, deal distribution, leaderboard, drop-off reasons, conversion trend, and activity feed — moves together when `period` (or a custom `start_date`/`end_date`) changes. The only thing that stays constant regardless of period is the *bucket size* of the conversion trend chart (`granularity`), since collapsing it to a single bucket would defeat its purpose as a trend line.

### 8.1. Dashboard Overview
**To** power the entire dashboard page (stat tiles, funnel, deal distribution, leaderboard, drop-off reasons, conversion trend, activity feed) in one call.

| | |
|---|---|
| Endpoint | `/api/v1/dashboard` |
| Method | `GET` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | `period=this_week\|this_month\|custom` (default `this_month`), `start_date?`, `end_date?` (both required, `422` otherwise, when `period=custom`), `granularity=daily\|weekly\|monthly` (default `monthly`), `limit=20` (1-100), `offset=0` |

`today` was removed as a period value — use `period=custom&start_date=<today>&end_date=<today>` instead. `custom` accepts any date range, e.g. `?period=custom&start_date=2026-07-01&end_date=2026-07-31`.

Example Response
```json
{
  "summary": {
    "leads_generated": { "value": 1248, "change_pct": 12.4 },
    "qualified_leads": { "value": 842, "change_pct": 8.1 },
    "deals_in_pipeline": { "value": 480, "change_pct": 3.2 },
    "deals_closed": { "value": 42, "change_pct": 12.5 },
    "num_accounts": { "value": 96, "change_pct": 5.0 }
  },
  "funnel": {
    "stages": [
      { "stage_name": "Received Requirements", "count": 642 },
      { "stage_name": "Qualified to Buy", "count": 512 },
      { "stage_name": "Evaluation", "count": 298 },
      { "stage_name": "Proposals", "count": 84 }
    ]
  },
  "deal_distribution": {
    "entries": [
      { "tier": "diamond", "count": 12, "total_value": 620000.0 },
      { "tier": "gold", "count": 210, "total_value": 4100000.0 },
      { "tier": "silver", "count": 180, "total_value": 1500000.0 },
      { "tier": "bronze", "count": 78, "total_value": 300000.0 }
    ]
  },
  "leaderboard": {
    "entries": [
      { "owner_id": 12, "owner_name": "Sarah Jenks", "owner_avatar_url": "/media/avatars/12.png", "revenue": 124000.0, "deals_closed": 9 },
      { "owner_id": 7, "owner_name": "Mike Ross", "owner_avatar_url": null, "revenue": 98000.0, "deals_closed": 6 }
    ]
  },
  "drop_off_reasons": {
    "entries": [
      { "reason": "Pricing too high", "stage_lost": "Proposals", "count": 45, "lost_value": 124500.0, "change_pct": 12.0 },
      { "reason": "Competitor chosen", "stage_lost": "Negotiation", "count": 28, "lost_value": 89200.0, "change_pct": -4.0 }
    ]
  },
  "conversion_trend": {
    "entries": [
      { "period": "2026-06-01", "stage_name": "Closed Won", "count": 14 },
      { "period": "2026-07-01", "stage_name": "Closed Won", "count": 18 }
    ]
  },
  "activity_feed": {
    "entries": [
      { "entity_type": "deal", "entity_id": 33, "type": "call", "note": "Called Acme Corp re: proposal terms", "created_by_name": "Sarah Jenks", "created_at": "2026-07-28T10:20:00Z" },
      { "entity_type": "lead", "entity_id": 101, "type": "note", "note": "Discussed Q3 expansion needs", "created_by_name": "Mike Ross", "created_at": "2026-07-27T15:05:00Z" }
    ]
  }
}
```

Per-section notes — **every section is scoped by `period`/`start_date`/`end_date`**, so switching the filter redraws the whole page consistently:

- **summary** — 5 stat tiles (Leads Generated, Qualified Leads, Deals in Pipeline, Deals Closed, Num Accounts), all scoped by `period`. `change_pct` compares the selected period against the immediately preceding period of equal length; `null` if the prior period had zero to compare against. "Deals closed" is **Closed Won only** (Closed Lost deals never count here) and is keyed off `Deal.updated_at`, since no `closed_at` column exists. `deals_in_pipeline` = open (not closed/cold) deals *opened* (`Deal.created_at`) during the period — not a live count of everything currently open regardless of age. `num_accounts` = accounts *created* (`Account.created_at`) during the period.
- **funnel** — Pipeline Funnel chart, ordered by `DealStage.sort_order` (per-company). Counts deals that **entered** each stage during the period (via `DealStageHistory`), not a live snapshot of current stage occupancy — a deal that moved on to a later stage within the period still counts under every stage it passed through.
- **deal_distribution** — Deal Distribution donut chart, scoped to deals *created* (`Deal.created_at`) in the period. `tier` enum: `diamond`, `gold`, `silver`, `bronze` (`Deal.tier`, same `LeadTier` enum shared with Lead/Account). Deals with no tier set are excluded.
- **leaderboard** — ranked by won-deal revenue *closed* (`Deal.updated_at`) in the period, descending. `owner_avatar_url` is the rep's `User.avatar_url` (a relative `/media/...` path, or `null` when they haven't uploaded one) so the row can show their photo without a second call. **No "% of target" figure** — see deferred note above. Only owners with at least one "Closed Won" deal closed in the period appear.
- **drop_off_reasons** — includes deals whose current stage is `Cold Deals` (`DealStage.is_cold=true`) or `Closed Lost`, grouped by `cold_reason`, scoped by `period` (drives `change_pct` only). `stage_lost` is the stage the deal was in immediately before moving to its current cold/lost stage (via `DealStageHistory`); `"Unknown"` if there's no prior stage (created directly into a cold/lost stage) or no history row at all. `change_pct` compares deal-loss *count* in the selected period vs. the immediately preceding period of equal length (by the timestamp of that stage transition, not `Deal.created_at`); `null` if the prior period had zero.
- **conversion_trend** — Conversion Trend line chart, scoped by both `granularity` (bucket size) and `period`/`start_date`/`end_date` (date range drawn) — a custom range zooms the chart into that window instead of always showing all-time. Counts `DealStageHistory` transitions *into* each stage, bucketed by `granularity` (the truncated start date of each bucket). Returns raw per-stage series across all stages — pick which stage(s) to plot client-side (e.g. "Closed Won" for a win-rate trend).
- **activity_feed** — merged feed across Deal/Lead/Account activity logs, scoped by `period` and paginated by `limit`/`offset`. `entity_type` is `deal`, `lead`, or `account`; `type` is that entity's activity type (`note`, `meeting`, `call`, `comment`, `follow_up`). Ordered `created_at` descending across all three sources merged together.

---

## 9. Notifications

Prefix: `/notifications`. **Any authenticated user, no permission code** — always self-scoped to the caller's own notifications.

### 9.1. List Notifications
| | |
|---|---|
| Endpoint | `/api/v1/notifications` |
| Method | `GET` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | `unread_only=false, type?, limit=20, offset=0` |

Example Response
```json
{
  "items": [
    { "id": 21, "type": "lead_assigned", "title": "New lead assigned", "body": "Alex Kim was assigned to you", "is_read": false, "read_at": null, "actor_id": 3, "entity_type": "lead", "entity_id": 101, "created_at": "2026-07-27T08:00:00Z" }
  ],
  "total": 1, "limit": 20, "offset": 0
}
```
`type` includes a computed `task_overdue` entry derived at read time from `Lead.next_follow_up_date` (no separate Task entity/scheduler). Notifications are polling-based — no real-time push, no email mirroring.

### 9.2. Unread Count
| | |
|---|---|
| Endpoint | `/api/v1/notifications/unread-count` |
| Method | `GET` |
| Permission Required | None (any authenticated user) |
| Params | N/A |

Example Response
```json
{ "unread_count": 4 }
```

### 9.3. Mark One Read
| | |
|---|---|
| Endpoint | `/api/v1/notifications/{notification_id}/read` |
| Method | `PATCH` |
| Permission Required | None (any authenticated user, must own the notification) |
| Params | path: `notification_id` |

Response: `NotificationRead`. Errors: `404` · `403` not the owner.

### 9.4. Mark Read (bulk / all)
| | |
|---|---|
| Endpoint | `/api/v1/notifications/read-all` |
| Method | `POST` |
| Permission Required | None (any authenticated user) |
| Params | N/A |

Example Request
```json
{ "ids": [21, 22] }
```
`ids: null` (or omitted) marks **all** of the caller's notifications read.

Example Response
```json
{ "updated": 2 }
```

### 9.5. Bulk Delete Notifications
| | |
|---|---|
| Endpoint | `/api/v1/notifications` |
| Method | `DELETE` |
| Permission Required | None (any authenticated user, must own all given ids) |
| Params | N/A |

Example Request
```json
{ "ids": [21, 22] }
```
Example Response
```json
{ "deleted": 2 }
```
Errors: `404` / `403` if any id doesn't belong to the caller.

---

## 10. Search

Prefix: `/search`. **Any authenticated user, no permission code.**

### 10.1. Global Search
**To** power a top-nav search box across core entities.

| | |
|---|---|
| Endpoint | `/api/v1/search` |
| Method | `GET` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | `q=""` (blank query returns empty results) |

Matches by name across Leads (first/last name), Accounts (company), Deals (deal name), and Contacts (first/last name). Capped at 5 results per entity type.

Example Response
```json
[
  { "id": 101, "label": "lead", "name": "Alex Kim" },
  { "id": 55, "label": "account", "name": "Acme Corp" },
  { "id": 33, "label": "deal", "name": "Acme Corp - Enterprise Plan" },
  { "id": 8, "label": "contact", "name": "Alex Kim" }
]
```

---

## 11. Documents

Prefix: `/documents`. **Any authenticated user, no permission code** — read-only union of Account and Deal documents for the sidebar Documents page. Per-row visibility is scoped the same as the Account/Deal list endpoints (owner-only unless `accounts.view_all`/`deals.view_all`). Upload/delete are **not** here — use the per-account (4.14–4.16) or per-deal (6.13–6.15) document endpoints for those.

### 11.1. List Documents
**To** power the Documents page — every document the caller can see, across Accounts and Deals, newest first.

| | |
|---|---|
| Endpoint | `/api/v1/documents` |
| Method | `GET` |
| Header Parameter | Bearer access token required |
| Permission Required | None (any authenticated user) |
| Params | `source?` (`account`\|`deal`, omit for both), `search?` (case-insensitive substring match on file name) |

Example Response
```json
[
  {
    "id": 3, "source": "account", "entity_id": 4, "entity_name": "Acme Corp",
    "file_name": "MSA_Draft.pdf", "file_url": "/media/account_documents/4_9f2c8a1e....pdf",
    "content_type": "application/pdf", "uploaded_by": 7,
    "created_at": "2026-07-24T10:20:00Z"
  },
  {
    "id": 6, "source": "deal", "entity_id": 33, "entity_name": "Acme Corp - Enterprise Plan",
    "file_name": "MSA_Draft.pdf", "file_url": "/media/deal_documents/33_ab12cd34....pdf",
    "content_type": "application/pdf", "uploaded_by": 12,
    "created_at": "2026-07-16T09:00:00Z"
  }
]
```
`entity_name` is the account's `company` or the deal's `deal_name`. `id` is only unique within its `source` (an account document and a deal document can share the same `id`) — use `(source, id)` together as the key. Same static `/media/...` serving as the per-entity document endpoints; not paginated.

---

## 12. Audit Log

Prefix: `/audit-log`. Logs every mutating action across users, leads, accounts, deals, contacts (create/update/delete, login/logout, password change, deal stage changes, lead-to-account conversion — including contact create/update via `POST /accounts/{id}/contacts`, not just standalone `POST /contacts`).

### 11.1. List Audit Log
| | |
|---|---|
| Endpoint | `/api/v1/audit-log` |
| Method | `GET` |
| Header Parameter | Bearer access token required |
| Permission Required | `audit_log.view` (Admin by default) |
| Params | `table_name?, action?, actor_id?, date_from?, date_to?, limit=20, offset=0` |

`table_name` valid values: `leads`, `accounts`, `deals`, `contacts`, `users`.
`action` valid values: `created`, `updated`, `deleted`, `login`, `logout`, `deactivated`.
Both are fixed, code-defined lists (no lookup endpoint) — hardcode them in the frontend, same as any other fixed enum in this API (e.g. `LeadSource`, `LeadTier`). `date_from`/`date_to` are plain dates (`YYYY-MM-DD`), not timestamps.

`description` is a free-text, human-readable line — its exact wording is not a stable contract, don't parse it. A few representative examples:
- Create/update/delete: `"Lead 'Alex Kim at Acme Corp' updated"`, `"Account 'Acme Corp' created"`, `"Contact 'Priya Nair' created"`
- Deal stage change: `"Deal 'Acme Corp - Enterprise Plan' moved from 'Evaluation' to 'Proposals'"`
- Lead conversion: a distinct `leads`/`updated` row `"Lead 'Acme Corp' converted to account 'Acme Corp'"`, alongside the account's own `accounts`/`created` row `"Account 'Acme Corp' created from lead 'Alex Kim' conversion"`
- Login/logout/password change: `"User 'jane.doe@company.com' logged in"`, `"User 'jane.doe@company.com' changed their password"`

Example Response
```json
{
  "items": [
    {
      "id": 501, "table_name": "deals", "record_id": 33, "action": "updated",
      "actor_id": 12, "actor_name": "Jane Doe",
      "description": "Deal 'Acme Corp - Enterprise Plan' moved from 'Evaluation' to 'Proposals'",
      "created_at": "2026-07-28T10:00:00Z"
    }
  ],
  "total": 1, "limit": 20, "offset": 0
}
```

---

## 13. Permissions

Prefix: `/permissions`. Requires `roles.manage`.

### 12.1. List Permissions
**To** fetch the full permission catalog, used to build the role-builder UI.

| | |
|---|---|
| Endpoint | `/api/v1/permissions` |
| Method | `GET` |
| Permission Required | `roles.manage` |
| Params | N/A |

Example Response
```json
[
  { "id": 1, "code": "leads.access", "label": "Access Leads", "description": "Can view and manage own leads", "module": "leads" }
]
```
Ordered by module, then code.

---

## 14. Roles

Prefix: `/roles`. Requires `roles.manage`.

### 13.1. Create Role
| | |
|---|---|
| Endpoint | `/api/v1/roles` |
| Method | `POST` |
| Permission Required | `roles.manage` |
| Params | N/A |

Example Request
```json
{ "name": "Sales Manager", "description": "Manages leads/accounts/deals", "permission_ids": [1, 2, 3] }
```
Example Response (`201`)
```json
{ "id": 2, "name": "Sales Manager", "description": "Manages leads/accounts/deals", "permissions": [ { "id": 1, "code": "leads.access", "label": "Access Leads", "description": "Can view and manage own leads", "module": "leads" } ] }
```
Errors: `409` role name already exists.

### 13.2. List Roles
| | |
|---|---|
| Endpoint | `/api/v1/roles` |
| Method | `GET` |
| Permission Required | `roles.manage` |
| Params | N/A |

Response: `list[RoleRead]`.

### 13.3. Update Role
| | |
|---|---|
| Endpoint | `/api/v1/roles/{role_id}` |
| Method | `PATCH` |
| Permission Required | `roles.manage` |
| Params | path: `role_id` |

Example Request
```json
{ "name": "Sales Manager", "description": "Manages leads/accounts/deals", "permission_ids": [1, 2, 3, 4] }
```
Response: `RoleRead`. Errors: `404` role not found · `409` name already exists.

### 13.4. Delete Role
| | |
|---|---|
| Endpoint | `/api/v1/roles/{role_id}` |
| Method | `DELETE` |
| Permission Required | `roles.manage` |
| Params | path: `role_id` |

Response: `204 No Content` (soft delete). Errors: `404` role not found.

---

*Full request/response schemas are also live in Swagger at `/docs` once the server is running.*
