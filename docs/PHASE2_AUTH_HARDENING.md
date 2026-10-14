# Phase 2 — Authentication hardening

**Date:** 2026-08-13
**Branch:** `feature/production-readiness`
**Scope:** Reliability of **existing** email + Google architecture. No OAuth redesign.

## What changed

| Area | Change |
|------|--------|
| `AuthValidators` | Shared pure validators for email / password / username / name |
| `humaniseAuthError` | Safer mapping; silent cancel; host vs network; truncate garbage |
| `isAuthCancellation` | Detect `GoogleSignInCancelled` so UI skips snackbars |
| Google cancel | Broader PlatformException cancel detection; empty callback rejected |
| `AuthNotifier.signInWithGoogle` | Cancel → `AsyncData` (not error); errors stay `AsyncError` |
| Login / register | Validators + empty humanised messages not shown |
| `resolveLandingRoute` | Pure landing rules (documented null/error → Home) |

## Preserved

```text
getOAuthSignInUrl → FlutterWebAuth2 → entangl:// → getSessionFromUrl
→ landingRouteAfterAuth → approval | home
```

## Tests

- `test/auth_errors_test.dart`
- `test/auth_validators_test.dart`
- `test/auth_landing_test.dart`

## Explicitly deferred to Phase 3

- Tighten missing-profile → Home policy
- Session expiry global redirect
- Device matrix (Google picker cancel / network mid-OAuth)

## Manual checks (device)

```text
[ ] Valid email login
[ ] Wrong password → friendly message
[ ] Empty fields blocked by validators
[ ] Google complete → home or approval
[ ] Google cancel → stay on login, no error toast
[ ] Unapproved → approval screen
[ ] Logout → login
```
