# Phase 3 — Session & account lifecycle

**Date:** 2026-08-13  
**Branch:** `feature/production-readiness`

## Explicit policies

| Situation | Destination | Notes |
|-----------|-------------|--------|
| No session / hard JWT failure | `/login` | Sign out when auth failure detected |
| Network error loading profile | `/home` | Do **not** logout offline users |
| Missing `profiles` row (after 1 retry) | `/approval-status` | Incomplete account, not full app |
| `pending` / `rejected` | `/approval-status` | Unchanged |
| `approved` (+ email-change allowed states) | `/home` | Unchanged |

## Code changes

| Piece | Role |
|-------|------|
| `SessionLifecycle` | Expiry, auth/network/missing-profile classification, `ensureFreshSession` |
| `GoRouterRefreshStream` | Re-run redirects on auth stream (logout → protected routes → login) |
| `landingRouteAfterAuth` | Fresh session + retry profile + failure mapping |
| Splash | `ensureFreshSession` before landing / FCM sync |
| Lifecycle resume | Uses `SessionLifecycle.ensureFreshSession` |
| Approval screen | Network/missing profile: stay + retry, not force-login |

## Push token lifecycle (unchanged, verified hooks)

```text
Login / signup → syncWithPreferences
Splash session → syncWithPreferences
Resume → syncWithPreferences
Logout / delete account → unregisterToken (before signOut)
Push OFF → unregisterToken
```

## Tests

- `test/session_lifecycle_test.dart`
- `test/auth_landing_test.dart` (updated policies)

## Manual checks

```text
[ ] Cold start with valid session → correct home/approval
[ ] Logout from settings → cannot open /home without login
[ ] Kill app after login → session restored
[ ] Airplane mode on resume → no crash, no false logout
[ ] Pending user → approval screen
```
