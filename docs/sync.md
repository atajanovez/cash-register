# POST /v1/sync — backend documentation

Received from the backend developer on 2026-10-23.

POST /api/v1/sync performs two jobs in one authenticated request:

1. Push locally queued writes in `operations`.
2. Pull ordered company changes after `cursor`.

The endpoint is company-scoped by the bearer token. Clients must not send a company or member ID in the sync envelope.

## Request

```http
POST /api/v1/sync HTTP/1.1
Authorization: Bearer <access-token>
Content-Type: application/json
```

```json
{
  "device_id": "20fe59b5-54a3-48f7-8548-8c027adf84e6",
  "cursor": 0,
  "pull_limit": 500,
  "operations": [
    {
      "operation_id": "3311d263-4144-4d54-8989-11de5b729db3",
      "type": "cash_register.create",
      "entity_id": "096f106d-6c62-49c7-858a-50be393f7852",
      "payload": {
        "name": "Main register",
        "members": [
          {"member_id": "15d7c4e1-52b5-4fbb-9270-27448bfb4437", "access": "modify"}
        ]
      }
    },
    {
      "operation_id": "421f2701-3cf2-45c4-a227-a0b4d866a4e6",
      "type": "record.create",
      "entity_id": "1e20b3fe-8d79-4287-b228-2b8138cead46",
      "payload": {
        "cash_register_id": "096f106d-6c62-49c7-858a-50be393f7852",
        "type": "income",
        "amount": 10025,
        "note": "Opening sale"
      }
    }
  ]
}
```

### Envelope fields

| Field | Required | Meaning |
| --- | --- | --- |
| device_id | yes | Stable client-generated UUID for this installation. |
| cursor | yes | Last applied change sequence. Use 0 for the first sync. Must not be negative. |
| pull_limit | no | Maximum changes returned. Valid range is 1–1000; omitted or out-of-range values use 500. |
| operations | no | Locally queued writes, processed in array order. Use [] or omit it for pull-only sync. |

### Operation fields

| Field | Required | Meaning |
| --- | --- | --- |
| operation_id | yes | Client-generated UUID used as the idempotency key. It is unique within the company. |
| type | yes | One of the supported operation types below. |
| entity_id | depends | Target UUID. Required for existing-entity operations; recommended for creates so related offline operations can refer to the new entity. |
| payload | depends | Operation-specific data. Omit it for operations with no payload. |

Amounts are integer minor units: 10025 means 100.25 TMT. Dates use RFC 3339, for example 2026-10-23T12:00:00Z.

## Supported operations

### record.create

`entity_id` is the new record UUID. The payload requires `cash_register_id`, `type`, and a positive `amount`.

```json
{
  "cash_register_id": "096f106d-6c62-49c7-858a-50be393f7852",
  "type": "receivable_opened",
  "amount": 5000,
  "deadline": "2026-11-01T12:00:00Z",
  "note": "Customer credit"
}
```

Supported record types are transfer_out, income, accrual_income, accrual_income_settled, expense,
receivable_opened, receivable_settled, payable_opened, and payable_settled.

- `destination_cash_register_id` is required for transfer_out.
- `parent_record_id` is required for settlement types.
- `deadline` is required for accrual_income, receivable_opened, and payable_opened.
- Do not send transfer_in; the server creates it automatically.

### cash_register.create

`entity_id` is the new register UUID. Payload:

```json
{
  "name": "Main register",
  "members": [
    {"member_id": "15d7c4e1-52b5-4fbb-9270-27448bfb4437", "access": "modify"}
  ]
}
```

Access is view or modify. This operation requires a manager.

### Register lifecycle operations

The following require `entity_id`, have no payload, and require a manager:

- cash_register.check
- cash_register.close
- cash_register.delete

### cash_register.access_set

`entity_id` is the register UUID. The supplied list replaces the complete access list. This operation requires a manager.

```json
{
  "members": [
    {"member_id": "15d7c4e1-52b5-4fbb-9270-27448bfb4437", "access": "view"}
  ]
}
```

### member.create

`entity_id` is the new member UUID. This operation requires a manager.

```json
{
  "full_name": "Ada Lovelace",
  "username": "ada",
  "password": "at-least-8-characters"
}
```

### member.update

`entity_id` is the member UUID. Send at least one property. This operation requires a manager.

```json
{
  "password": "new-password",
  "is_active": true
}
```

## Response

The endpoint returns HTTP 200 when the sync envelope is valid, even when individual operations are rejected.

```json
{
  "results": [
    {
      "operation_id": "3311d263-4144-4d54-8989-11de5b729db3",
      "status": "accepted",
      "entity_id": "096f106d-6c62-49c7-858a-50be393f7852"
    },
    {
      "operation_id": "421f2701-3cf2-45c4-a227-a0b4d866a4e6",
      "status": "rejected",
      "error_code": "conflict",
      "message": "current amount is insufficient for this record"
    }
  ],
  "changes": [
    {
      "sequence": 184,
      "entity_type": "cash_registers",
      "entity_id": "096f106d-6c62-49c7-858a-50be393f7852",
      "action": "upsert",
      "payload": {"id": "096f106d-6c62-49c7-858a-50be393f7852", "name": "Main register"},
      "changed_at": "2026-10-23T10:15:30Z"
    }
  ],
  "next_cursor": 184,
  "has_more": false
}
```

### Applying the response

1. Match every result to its outbox entry by `operation_id`.
2. Remove accepted entries from the outbox.
3. Keep rejected entries for user review. After correcting one, enqueue it with a new `operation_id`; replaying the old ID returns the stored result.
4. Apply changes in ascending `sequence` order. For `upsert`, replace the local entity with `payload`; for `delete`, remove it using `entity_type` and `entity_id` (the payload is absent).
5. Persist `next_cursor` only after all returned changes have been committed locally.
6. If `has_more` is true, immediately call sync again with that `next_cursor` until it becomes false.

Possible `entity_type` values are `members`, `cash_registers`, `records`, and `cash_register_members`.
Access-row IDs use `<cash_register_id>:<member_id>`.

## Idempotency and retries

- Operations are processed in request order, but the batch is not atomic. One rejection does not stop later operations.
- `operation_id` is the idempotency key. Retrying the same operation returns its previously stored accepted or rejected result and does not apply it again.
- Keep the same `operation_id` when retrying because of a timeout or network failure.
- Use a new `operation_id` only when the operation itself or its payload has been corrected.
- Create operations should use client-generated `entity_id` values. This lets later queued operations safely reference entities that have not yet reached the server.

## Request-level errors

Malformed JSON, a missing/invalid `device_id`, or a negative cursor rejects the whole request with HTTP 400
and the standard API error envelope. Authentication errors reject the request with HTTP 401. Domain and
permission failures for individual operations appear in `results` instead of changing the HTTP status.

## Status (2026-10-23)

Live server still returns `500 internal_error` for every valid request, including a pull with no
operations, requests copied from this document, and a pull from a brand-new empty company
(`ClaudeSyncTest-10230940`). Request validation (400/401) works. See `sync-test-report.md` (runs 1–3).

## Client implementation (`lib/core/offline/`)

- **`LocalStore`:** the server snapshot, the outbox of operations made on this device, `cursor`, `device_id`, and an id map. Saved atomically to `kassa_<company>_<member>.json` in the app support folder. Logout deletes it.
- **`LocalView`:** the snapshot with every pending or sent operation replayed on top, using the server's balance rules. Screens read only this, so everything works offline.
- **`SyncEngine`:** pushes the outbox with `POST /v1/sync` (batches of 200) and applies `changes`, repeating while `has_more`.
  - Runs on start, when the connection returns, on app resume, every 3 minutes, and right after each change.
  - Online, a refused change is thrown back to the form. Offline it waits, and refusals found later show in the sync sheet, where the user can discard them.
  - **Fallback:** while `/v1/sync` answers 5xx/404/405, it replays each operation through its REST call, records the server ids in the id map, and re-downloads everything. It tries the endpoint again after 10 minutes.
- **Online only:** member create/update (they carry passwords) and pinning.

