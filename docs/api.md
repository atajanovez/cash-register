# Cash Register API — verified behaviour

Base URL: `https://cashregister.adyl.org/api` (all paths below start with `/v1`).
Auth: `Authorization: Bearer <access_token>`. Amounts are integers in minor units.

Verified against the live server on 2026-10-21. Real responses are in
[`test/fixtures/api/`](../test/fixtures/api/).

## Errors

```json
{"error": {"code": "username_taken", "message": "…", "fields": {"username": "…"}}}
```

`fields` is present only for some errors. Codes seen:

| Status | code | When |
|---|---|---|
| 400 | `invalid_request` | missing/invalid body values (message says which) |
| 400 | `invalid_identifier` | malformed UUID in the path |
| 400 | `deadline_required` | opening record without `deadline` (has `fields.deadline`) |
| 400 | `invalid_device_id`, `invalid_cursor` | sync input (has `fields`) |
| 401 | `unauthorized` | bad credentials, missing/invalid token, or member deactivated ("member is inactive or no longer exists") |
| 403 | `forbidden` | "manager access required" or "modify access to the cash register is required" |
| 404 | `not_found` | missing, or not visible to this member |
| 409 | `conflict` | business rule (message says which); company name taken on signup |
| 409 | `username_taken`, `cash_register_name_taken` | have `fields` |
| 500 | `internal_error` | |

## Auth

- `POST /companies` → 201 `{company: {id, name, manager_id, created_at}, manager: Member, access_token}`
- `POST /auth/login` → 200 `{member: Member, access_token}`; company name is case-insensitive; inactive members get 401.
- JWT claims: `{sub: member id, company_id, manager: bool, exp}`; tokens last 30 days. **The role is only in the `manager` claim.**

## Members

`Member = {id, full_name, username, company_id, is_active, created_at}`

- `GET /members` → `Member[]` (any member; no manager flag in the list)
- `POST /members` (manager) → 201 `Member`
- `PATCH /members/{id}` (manager) `{password?, is_active?}` → 200 `Member`; empty body is 400; deactivating the manager is 409. A deactivated member's existing token stops working immediately.

## Cash registers

`CashRegister = {id, company_id, name, current_amount, real_amount, created_at, checked_at?, closed_at?}`

- `GET /cash-registers` → `CashRegister[]`. Members only see registers they are assigned to. Filters: `search`, `only_closed`, `only_checked` (includes closed), `unsettled`, `sort`, `order`.
- `GET /cash-registers/{id}` → `{cash_register: CashRegister, members: [{id, full_name, username, is_active, access: "view"|"modify"}]}`; not assigned → 404.
- `POST /cash-registers` (manager) `{name, members?}` → 201 `CashRegister`; names are unique per company.
- `PUT /cash-registers/{id}/members` (manager) `{members}` → 204; replaces the whole list.
- `POST /{id}/check` (manager) → 200 `CashRegister`; idempotent.
- `POST /{id}/close` (manager) → 200; requires checked, `current == real`, everything settled.
- `DELETE /{id}` (manager) → 204; only closed registers.

- `is_pinned` (bool) on `CashRegister` — **not on the live server yet (2026-10-25).** The server does not sort by it; the app lists pinned registers first (`RegisterQuery.applyLocally`). The app assumes `PATCH /{id}` with `{"is_pinned": bool}` to change it (manager only); the live server answers 405 today. Confirm the real endpoint with the backend.

Lifecycle: **open → checked → closed → deleted**.

| State | Accepts |
|---|---|
| open | every record type |
| checked | transfers and settlements |
| closed | outgoing `transfer_out` only; cannot be a transfer destination |

## Records

- `POST /cash-registers/{id}/records` (modify access) → 201 record.
- `GET /cash-registers/{id}/records` (view access) → array, newest first. Filters: `search`, `type`, `created_member`, `only_unsettled`, `destination`, `sort`, `order`, `limit` (default 50), `offset`. No total count — page until a page is shorter than `limit`.

List items add `creator {id, full_name, username, is_active}`, `parent` (record or null), `children` (direct settlements), `destination`/`source` (`{id, name}` or null). Transfers carry `counterpart_record_id`; `transfer_in` has `source_cash_register_id`. There is no "remaining" field: unsettled = `amount − sum(children.amount)`.

Effect on balances:

| Type | current_amount | real_amount | Needs |
|---|---|---|---|
| income | + | + | |
| expense | − | − | enough current |
| transfer_out / transfer_in | − / + | − / + | destination; modify on both; enough current |
| accrual_income | | + | deadline |
| accrual_income_settled | + | | parent |
| receivable_opened | − | | deadline; enough current |
| receivable_settled | + | | parent |
| payable_opened | + | | deadline |
| payable_settled | − | | parent; enough current |

So `real = current + open accruals + open receivables − open payables`. A settlement may be partial but not exceed what is left; its type must match the parent.

## Known server issues (2026-10-21)

1. **`POST /sync` returns 500 `internal_error` for every valid request** (manager or member, with or without operations). Input validation (bad UUID, negative cursor) still works, so the failure happens after parsing — likely a missing migration or a query bug.
2. **`GET /cash-registers` and `GET /cash-registers/{id}` return 500 (since 2026-10-25)** for every member, likely the `is_pinned` change deployed without its migration. Members and records endpoints still work.
3. **Deleting a closed register leaves other registers' balances stale.** The cascade removes the `transfer_in` rows it created elsewhere, but the destination's `current_amount`/`real_amount` are not reduced (the test "Safe" register shows 20 600 while its records sum to 20 200).
