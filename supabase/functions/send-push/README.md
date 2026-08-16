# send-push

Deployed Edge Function that turns `notifications` inserts into FCM messages.

## Deploy

```bash
supabase functions deploy send-push --project-ref lmohyfcmiftvuluhyaqh
```

## Secrets

| Secret | Purpose |
|--------|---------|
| `FIREBASE_PROJECT_ID` | e.g. `entangl-c11b2` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Full SA JSON string |
| `PUSH_WEBHOOK_SECRET` | Must match Vault `push_webhook_secret` used by `notify_send_push` |

## Phase 5 behavior

1. Load `device_tokens` (+ optional `profiles.fcm_token`) for `record.user_id`
2. Build title/body from `type` + actor profile
3. Send FCM HTTP v1 with **data** keys for Flutter routing:
   - `type`, `actor_id`, `post_id`, `comment_id`, `notification_id`
4. On FCM `UNREGISTERED` / invalid token → **delete** that `device_tokens` row
5. Never deletes the `notifications` inbox row (source of truth stays intact)

## Auth

Accepts either:

- Header `x-push-secret` / `x-webhook-secret` == `PUSH_WEBHOOK_SECRET`, or
- `Authorization: Bearer <service_role>`
