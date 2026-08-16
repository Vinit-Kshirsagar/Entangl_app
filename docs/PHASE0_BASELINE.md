# Phase 0 — Production readiness baseline

**Date:** 2026-08-13  
**Branch:** `feature/production-readiness`  
**Parent tip:** `feature/fcm-refactor-ui-updates` @ `eb5c28c`  
**Scope:** Record only — **no feature implementation, no bulk refactors**

---

## 0.1 Branch strategy (important)

Roadmap suggested:

```bash
git checkout main && git pull && git checkout -b feature/production-readiness
```

**What we actually did:**

| Item | Value |
|------|--------|
| New branch | `feature/production-readiness` |
| Created from | `feature/fcm-refactor-ui-updates` (`eb5c28c`) |
| `main` left at | `4bc2233` — **not** used as branch base |

**Why not `main` alone?**  
`main` is **behind** the product tip by 8 commits (theme, FCM, approval, Google OAuth, etc.). Chunk 1 is about hardening the **current** app (Google return, FCM delivery). Basing production-readiness on `main` would drop that work.

**`main` was not modified.**

---

## 0.2 Repository health

### flutter doctor

```text
Flutter 3.44.9 (stable) · Dart 3.12.2
Android toolchain SDK 36 · Xcode 26.3 · Chrome
Connected: macOS, Chrome (no physical Android attached at baseline time)
No issues found
```

### flutter pub get

```text
Succeeded
89 packages have newer versions incompatible with constraints (recorded, not upgraded)
```

### flutter analyze

**Command used for app signal:** `flutter analyze lib test`  
(Full-repo analyze also scanned `build/macos/SourcePackages` and reported third-party mock errors — noise.)

| Severity | Count in `lib` + `test` |
|----------|-------------------------|
| error | **0** |
| warning | **5** (unnecessary casts in repositories) |
| info | **28** (mostly `withOpacity` deprecation; 1 `valid_regexps` on `emoji_text.dart`) |
| Exit | 0 |

**Not auto-fixed** (per Phase 0 rules).

Sample warnings:

- `lib/data/repositories/comments_repository.dart` — unnecessary_cast  
- `lib/data/repositories/users_repository.dart` — unnecessary_cast (×4)  
- Widespread `withOpacity` → prefer `.withValues()`  
- `lib/shared/widgets/emoji_text.dart` — `valid_regexps` info  

### flutter test

```text
All tests passed: 26
Exit 0
```

Suites: `masonry_engine_test`, `post_format_test`, `scrap_content_test`, `settings_screen_test`, `widget_test` (models).

**Note:** No automated tests yet for Google OAuth, FCM tap routing, or session expiration.

### flutter build apk --debug

```text
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Exit 0
```

---

## 0.3 Current authentication (as of code tip)

| Behavior | Status (code/docs) |
|----------|---------------------|
| Email login / register | Implemented |
| Google via `getOAuthSignInUrl` + `flutter_web_auth_2` + `entangl://auth-callback` | Implemented (`auth_repository.dart`, `AppConstants.oauthRedirectTo`) |
| Approval gate → home | Implemented (`landingRouteAfterAuth`) |
| Logout | Implemented; unregisters FCM token before sign-out |
| Session on splash | Session → landing route; no session → login |
| Missing profile fallback | **Review later (Phase 3):** may land Home if profile fetch fails |
| In-app set-new-password | **Missing** (forgot password → Site URL) |

**Manual device matrix (Phase 0.3):** not fully re-run on a physical device during this baseline window (no Android device attached to doctor). Treat as **code-level baseline**; device re-verify in Phases 2–3.

Known past issue (fixed in tree): wrong Supabase host typo in `secrets.dart` caused false “No internet” on login. Correct host: `lmohyfcmiftvuluhyaqh.supabase.co`.

---

## 0.4 Current notifications (as of code tip)

### Working (delivery + inbox)

| Piece | Status |
|-------|--------|
| DB triggers → `notifications` | Live (backend) |
| In-app inbox + mark read / dismiss | Working |
| Android FCM token → `device_tokens` | Working (`PushNotificationService`) |
| Token hooks (login, push toggle, resume, logout) | Working |
| `notify_send_push` → Edge `send-push` → FCM | Live (backend) |
| Foreground local notification display | Working |
| Background / terminated tray | Working when token + Edge OK |

### Incomplete (Chunk 1 Phases 4–5)

| Piece | Status |
|-------|--------|
| `NotificationRouter` | **Missing** |
| FCM `onMessageOpenedApp` / `getInitialMessage` navigation | **Missing** |
| Local notification tap handler | Payload set; **no** routing callback |
| In-app tile tap | Always → **actor profile** (not post/comment) |
| `/post/:id` route | **Missing** |
| Stale FCM `UNREGISTERED` cleanup | **Not finished** |
| Duplicate notification inserts | **Known issue** |
| iOS / APNs | **Deferred** |
| Client `activity-push` | **Not called** (send-push only) |

---

## 0.5 Known failures / risks (do not fix in Phase 0)

1. **No post deep link route** — blocks complete notification UX.  
2. **Split routing behavior** — FCM vs inbox vs ideal matrix.  
3. **`main` lag** — merge strategy needed before release.  
4. **Secrets in repo pattern** — `lib/core/secrets.dart` holds keys (env move = later chunk).  
5. **Offline banner** — DNS lookup to 8.8.8.8 can false-negative on some networks (separate from secrets typo).  
6. **Analyze noise** if analyzing entire repo including `build/`. Prefer `flutter analyze lib test`.  
7. **Uncommitted docs** at baseline start (CURRENT_APP, FCM_TEST refresh, etc.) — staged only if included in baseline commit.

---

## 0.6 Acceptance checklist

```text
[x] feature/production-readiness exists
[x] main is untouched
[x] flutter pub get succeeds
[x] flutter analyze result recorded
[x] flutter test result recorded (26 passed)
[x] Android debug APK build succeeds
[x] current authentication behavior recorded (code-level)
[x] current notification behavior recorded
[x] known failures documented
[ ] full manual device matrix (deferred to Phases 2–4 with real Android)
```

---

## 0.7 Next (do not start until reviewed)

**Phase 1 — Architecture audit only** (analysis report, no large refactor).

---

## Chunk 1 protocol reminder

```text
One phase / one task → implement → test → commit → review → next
Phases 0–5 only in Chunk 1. No security/performance mega-refactor yet.
```
