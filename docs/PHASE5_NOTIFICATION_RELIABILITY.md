# Phase 5 — Notification reliability

**Date:** 2026-08-13  
**Branch:** `feature/production-readiness`

## Goals

| Item | Status |
|------|--------|
| Stale FCM token cleanup on UNREGISTERED | **Implemented in `send-push` source** (deploy required) |
| Duplicate notification inserts | **SQL idempotency in `create_notification`** (run SQL) |
| Token lifecycle (client) | Verified + rotation replaces previous row |
| Push failure ≠ delete inbox row | Preserved (only `device_tokens` rows drop) |
| Flutter does not call `activity-push` | Unchanged |

---

## 5.1 Stale tokens (server)

**File:** `supabase/functions/send-push/index.ts`

When FCM returns UNREGISTERED / invalid registration:

```text
send-push
  → FCM error UNREGISTERED
  → DELETE device_tokens WHERE token = …
  → clear profiles.fcm_token if it matched
  → notifications row untouched
```

### You must deploy

```bash
supabase functions deploy send-push --project-ref lmohyfcmiftvuluhyaqh
```

Confirm secrets still set: `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `PUSH_WEBHOOK_SECRET`.

---

## 5.2 Duplicates (database)

**Investigation:** Same-timestamp duplicate like/follow rows with a single attached trigger name → double insert into `create_notification` (or historical dual path).

**Fix (source):** make `create_notification` skip identical events within **5 seconds**.

**File:** `supabase/sql/05_notification_dedupe.sql`

### You must run in SQL Editor

Paste/run `supabase/sql/05_notification_dedupe.sql`.

Optional: use the SELECT at the bottom of that file to list remaining historical dupes.

---

## 5.3 Client token lifecycle

| Event | Behavior |
|-------|----------|
| Login / Push ON / resume | `registerToken` → upsert |
| Token rotation | Delete previous token row, upsert new |
| Push OFF / logout | Delete current token row |

Helpers: `lib/data/services/device_token_lifecycle.dart`  
Tests: `test/device_token_lifecycle_test.dart`

---

## 5.4 Failure model

```text
FCM fails
  → inbox notifications row still exists
  → in-app list works
  → only dead device_tokens are removed (after deploy)
```

---

## Manual checklist

```text
[ ] Run 05_notification_dedupe.sql
[ ] Deploy send-push
[ ] Like once → one inbox row (not two)
[ ] Install/reinstall app → old token eventually removed on next failed send
[ ] Push OFF → row gone; activity still creates notifications row
```

---

## Chunk 1 final status (notifications)

| Layer | State |
|-------|--------|
| Event generation + DB rows | Working |
| Android delivery | Working (with tokens) |
| Tap routing | Phase 4 done |
| Stale tokens / dedupe | Phase 5 sources ready — **apply on Supabase** |
