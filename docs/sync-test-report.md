# POST /v1/sync — test results

Run: 2026-10-22 08:58 UTC  
Server: `https://cashregister.adyl.org/api/v1/sync`  
Headers: `Authorization: Bearer <JWT from /v1/auth/login>`, `content-type: application/json`  
Company: test company `ClaudeTest-10211838`

| # | Case | User | Request body | Status | Response |
|---|---|---|---|---|---|
| 1 | Swagger example, unchanged | manager | `{"device_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6", "cursor": 0, "pull_limit": 500, "operations": [{"operation_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6", "type": "record.create", "entity_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6", "payload": {"additionalProp1": {}}}]}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 2 | Required fields only (pull) | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 3 | Pull with pull_limit 500 | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "pull_limit": 500}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 4 | Pull with pull_limit 1 | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "pull_limit": 1}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 5 | Pull from cursor 1, pull_limit 1000 | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 1, "pull_limit": 1000}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 6 | Empty operations array | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "operations": []}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 7 | Operation with empty payload | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "operations": [{"operation_id": "3e843225-2cad-45e7-8f34-4b5f2782d70b", "type": "record.create", "entity_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63", "payload": {}}]}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 8 | Operation without entity_id / payload | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "operations": [{"operation_id": "741b4822-6e65-4cad-8e88-d914b78b4474", "type": "cash_register.check"}]}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 9 | record.create, entity_id = register | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "operations": [{"operation_id": "652199b7-2064-4a51-9392-496dc349d595", "type": "record.create", "entity_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63", "payload": {"type": "income", "amount": 100, "note": "sync test"}}]}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 10 | record.create, cash_register_id in payload | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "operations": [{"operation_id": "df1d6b10-fcec-4c17-8821-c502c5b85d58", "type": "record.create", "entity_id": "a37edc1f-56dc-43da-982e-bb2134a9743e", "payload": {"cash_register_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63", "type": "income", "amount": 100, "note": "sync test"}}]}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 11 | cash_register.create | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "operations": [{"operation_id": "2c4dc1a4-6526-4975-9ce3-927ba87ebda5", "type": "cash_register.create", "entity_id": "483a944f-be15-4b9c-8da9-42b9719ec674", "payload": {"name": "Sync test"}}]}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 12 | member.update | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0, "operations": [{"operation_id": "972bd27f-2588-43fc-a56c-21df3ccaa29f", "type": "member.update", "entity_id": "94b248ad-2471-45a6-9cc7-f3100ba505ae", "payload": {"is_active": true}}]}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 13 | Required fields only, as a member (not manager) | grace | `{"device_id": "7ca105b5-749e-44c7-bd83-2e5108647fff", "cursor": 0}` | **500** | `{"error":{"code":"internal_error","message":"an unexpected error occurred"}}` |
| 14 | Invalid device_id (control) | manager | `{"device_id": "abc", "cursor": 0}` | **400** | `{"error":{"code":"invalid_device_id","message":"device_id must be a UUID","fields":{"device_id":"device_id must be a UUID"}}}` |
| 15 | Negative cursor (control) | manager | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": -1}` | **400** | `{"error":{"code":"invalid_cursor","message":"cursor cannot be negative","fields":{"cursor":"cursor cannot be negative"}}}` |
| 16 | No token (control) | none | `{"device_id": "a2b76bb2-811e-43ff-87a5-8857dc8ce7eb", "cursor": 0}` | **401** | `{"error":{"code":"unauthorized","message":"bearer token required"}}` |

## Summary

- Every valid request returns **500 `internal_error`** (cases 1–13): with or without operations, any `pull_limit`, any cursor, as the manager or as a member.
- Invalid input is rejected correctly (cases 14–16: 400 / 400 / 401), so the body is parsed and validated. The crash happens after validation.
- Nothing was saved by cases 7–12 (no new record, register or member change).
- Likely cause: a missing table or migration, or a failing query in the sync handler. The server log for any of these requests should show the real error.

## About `"payload": {"additionalProp1": {}}`

Swagger fills that in automatically because the spec declares `payload` as `{type: object, additionalProperties: true}`, meaning "any keys". It is a placeholder, not the real format. The spec does not say which keys each operation type expects.

Please document the `payload` (and what `entity_id` means) for each operation type:

| Operation type | `entity_id` is… | `payload` keys |
|---|---|---|
| `record.create` | ? (new record id or register id) | ? |
| `cash_register.create` | ? | ? |
| `cash_register.check` | ? | ? |
| `cash_register.close` | ? | ? |
| `cash_register.delete` | ? | ? |
| `cash_register.access_set` | ? | ? |
| `member.create` | ? | ? |
| `member.update` | ? | ? |

And the shape of the 200 response (per-operation results, `changes`, `next_cursor`, `has_more`).

## Run 2 — payload rules from backend (2026-10-22 11:50 UTC)

Rules: `entity_id` = the item's own id; URL params (`cash_register_id`, `member_id`) + REST body go inside `payload`.

### 1. Pull only (no operations)

```json
{
  "device_id": "de5f0526-237d-4293-b9e7-1952cf4e8e60",
  "cursor": 0,
  "pull_limit": 500
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 2. record.create: entity_id = new record, payload has cash_register_id

```json
{
  "device_id": "de5f0526-237d-4293-b9e7-1952cf4e8e60",
  "cursor": 0,
  "pull_limit": 500,
  "operations": [
    {
      "operation_id": "2fa67c77-d057-48cc-ab55-ce19fd740b87",
      "type": "record.create",
      "entity_id": "16ff310f-f372-4b49-8831-92e60531e0bd",
      "payload": {
        "cash_register_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63",
        "type": "income",
        "amount": 100,
        "note": "sync test"
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 3. record.create: + member_id (manager)

```json
{
  "device_id": "de5f0526-237d-4293-b9e7-1952cf4e8e60",
  "cursor": 0,
  "pull_limit": 500,
  "operations": [
    {
      "operation_id": "63c4e845-6d8b-45ba-a2e1-46bd5cbd8c3c",
      "type": "record.create",
      "entity_id": "73680d14-97a0-4f43-919f-1975e7025d8e",
      "payload": {
        "cash_register_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63",
        "member_id": "ca4496a7-9faf-4f94-9673-f2d344594329",
        "type": "income",
        "amount": 100,
        "note": "sync test"
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 4. cash_register.create: entity_id = new register, members with member_id

```json
{
  "device_id": "de5f0526-237d-4293-b9e7-1952cf4e8e60",
  "cursor": 0,
  "pull_limit": 500,
  "operations": [
    {
      "operation_id": "8fbe1c2f-f5bb-45ce-a102-3b4f22134d69",
      "type": "cash_register.create",
      "entity_id": "cb1ef9f3-f3e9-4273-bccc-b8e1d2ff81f7",
      "payload": {
        "cash_register_id": "cb1ef9f3-f3e9-4273-bccc-b8e1d2ff81f7",
        "name": "Sync test",
        "members": [
          {
            "member_id": "94b248ad-2471-45a6-9cc7-f3100ba505ae",
            "access": "view"
          }
        ]
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 5. cash_register.access_set: entity_id = register, payload cash_register_id + members

```json
{
  "device_id": "de5f0526-237d-4293-b9e7-1952cf4e8e60",
  "cursor": 0,
  "pull_limit": 500,
  "operations": [
    {
      "operation_id": "4a001dbd-f700-480d-81ab-487307258422",
      "type": "cash_register.access_set",
      "entity_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63",
      "payload": {
        "cash_register_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63",
        "members": [
          {
            "member_id": "94b248ad-2471-45a6-9cc7-f3100ba505ae",
            "access": "modify"
          }
        ]
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 6. member.update: entity_id = member, payload member_id

```json
{
  "device_id": "de5f0526-237d-4293-b9e7-1952cf4e8e60",
  "cursor": 0,
  "pull_limit": 500,
  "operations": [
    {
      "operation_id": "19ee6a25-2654-4e0d-bc4d-68a7cb45da46",
      "type": "member.update",
      "entity_id": "94b248ad-2471-45a6-9cc7-f3100ba505ae",
      "payload": {
        "member_id": "94b248ad-2471-45a6-9cc7-f3100ba505ae",
        "is_active": true
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 7. member.create: entity_id = new member, payload member_id

```json
{
  "device_id": "de5f0526-237d-4293-b9e7-1952cf4e8e60",
  "cursor": 0,
  "pull_limit": 500,
  "operations": [
    {
      "operation_id": "0c0a90f4-63bd-4e33-8971-a6326ade3c70",
      "type": "member.create",
      "entity_id": "89e5debd-cf95-4e15-8230-f95cd9b81a5c",
      "payload": {
        "member_id": "89e5debd-cf95-4e15-8230-f95cd9b81a5c",
        "full_name": "Sync Test",
        "username": "synctest",
        "password": "password123"
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```


## Run 3 — exactly as in docs/sync.md (2026-10-23 04:39 UTC)

### 1. Pull only, operations omitted

```json
{
  "device_id": "e5e04e49-ff7f-40c2-bcb7-490bcf220f63",
  "cursor": 0,
  "pull_limit": 500
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 2. Pull only, operations []

```json
{
  "device_id": "e5e04e49-ff7f-40c2-bcb7-490bcf220f63",
  "cursor": 0,
  "pull_limit": 500,
  "operations": []
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 3. Documentation example (cash_register.create + record.create), real member id

```json
{
  "device_id": "e5e04e49-ff7f-40c2-bcb7-490bcf220f63",
  "cursor": 0,
  "pull_limit": 500,
  "operations": [
    {
      "operation_id": "7b7d9a47-3ffb-450e-a403-28b5173ca74c",
      "type": "cash_register.create",
      "entity_id": "4b5927d6-b0f7-4631-bb02-a2f4b8a9e9d2",
      "payload": {
        "name": "Sync doc test",
        "members": [
          {
            "member_id": "94b248ad-2471-45a6-9cc7-f3100ba505ae",
            "access": "modify"
          }
        ]
      }
    },
    {
      "operation_id": "70561a72-8d77-45f9-b2fd-e0e07133a9fc",
      "type": "record.create",
      "entity_id": "6442f187-3bb1-4865-97cf-dfc0eda05475",
      "payload": {
        "cash_register_id": "4b5927d6-b0f7-4631-bb02-a2f4b8a9e9d2",
        "type": "income",
        "amount": 10025,
        "note": "Opening sale"
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 4. record.create into existing open register Safe

```json
{
  "device_id": "e5e04e49-ff7f-40c2-bcb7-490bcf220f63",
  "cursor": 0,
  "operations": [
    {
      "operation_id": "0ef6fdb1-7c79-4d60-ad3c-e38255490375",
      "type": "record.create",
      "entity_id": "86ffd143-7f62-4073-b405-d33e51d18e68",
      "payload": {
        "cash_register_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63",
        "type": "income",
        "amount": 100,
        "note": "sync doc test"
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 5. record.create receivable_opened with deadline

```json
{
  "device_id": "e5e04e49-ff7f-40c2-bcb7-490bcf220f63",
  "cursor": 0,
  "operations": [
    {
      "operation_id": "68171d0c-e3f5-40c9-b573-5328c9ca7df3",
      "type": "record.create",
      "entity_id": "ca0f65f5-a421-43ba-8001-307f535a1141",
      "payload": {
        "cash_register_id": "7698e5b4-2289-49d9-91e1-36d3d4872f63",
        "type": "receivable_opened",
        "amount": 5000,
        "deadline": "2026-11-01T12:00:00Z",
        "note": "Customer credit"
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 6. member.update (no payload member_id)

```json
{
  "device_id": "e5e04e49-ff7f-40c2-bcb7-490bcf220f63",
  "cursor": 0,
  "operations": [
    {
      "operation_id": "a94989be-3e2e-4469-8fbc-d23af26a145f",
      "type": "member.update",
      "entity_id": "94b248ad-2471-45a6-9cc7-f3100ba505ae",
      "payload": {
        "is_active": true
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

### 7. Rejected-operation path: record.create into unknown register

```json
{
  "device_id": "e5e04e49-ff7f-40c2-bcb7-490bcf220f63",
  "cursor": 0,
  "operations": [
    {
      "operation_id": "40c8bf7b-bd42-44b5-b2e4-a8625a9135a8",
      "type": "record.create",
      "entity_id": "41e9e1bf-8b5f-4e24-a0d7-a954a0c70766",
      "payload": {
        "cash_register_id": "2d9997c0-5c75-4624-8313-628e35cf7581",
        "type": "income",
        "amount": 100
      }
    }
  ]
}
```

**HTTP 500**

```json
{"error":{"code":"internal_error","message":"an unexpected error occurred"}}
```

