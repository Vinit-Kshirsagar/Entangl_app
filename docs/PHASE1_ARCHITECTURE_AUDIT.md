# Phase 1 — Production architecture audit

**Date:** 2026-08-13  
**Branch:** `feature/production-readiness`  
**Baseline:** [PHASE0_BASELINE.md](PHASE0_BASELINE.md)  
**Scope:** Analysis only — **no large refactors, no new routes implemented**

Intended direction (verified against tree):

```text
Screen / Widget
      ↓  watches / calls
Riverpod provider / notifier
      ↓
Repository
      ↓
SupabaseService  |  Firebase (FCM only)
      ↓
Backend
```

---

## Architecture Audit

### WORKING

#### Layers

| Area | Finding |
|------|---------|
| Feature-first folders | `lib/features/*` with screens / providers / widgets |
| Data layer | `lib/data/repositories/*` + `models/` + `services/` |
| Domain scrap types | `lib/domain/scrap/scrap_content.dart` — **no** `package:flutter` import |
| Shared UI | `lib/shared/widgets`, theme providers |
| Core infra | router, theme, layout, constants, utils |
| Repositories | Talk to `SupabaseService.client` — **no** navigation imports in `lib/data/` |
| Feed pattern | `FeedNotifier` → `PostsRepository` → Supabase (clean) |
| Notifications data | `NotificationsRepository` reads/writes `notifications` only |

#### Authentication

| Piece | Location | Status |
|-------|----------|--------|
| Email sign-in / sign-up | `AuthRepository` | Present |
| Google OAuth (in-app sheet) | `AuthRepository.signInWithGoogle` | **Preserved intentional design** |
| Cancel handling | `GoogleSignInCancelled` | Present; notifier swallows cancel |
| Landing after auth | `landingRouteAfterAuth()` | Approval vs Home |
| Auth notifier | No navigation inside notifier | Callers navigate |
| Redirect scheme | `AppConstants.oauthRedirectTo` = `entangl://auth-callback` | Matches platform config |
| Android callback | `CallbackActivity` + `scheme=entangl` | In `AndroidManifest.xml` |
| iOS URL scheme | `entangl` in `Info.plist` | Present |

**Confirmed Google flow (do not redesign):**

```text
getOAuthSignInUrl(provider: google, redirectTo: entangl://auth-callback)
        ↓
FlutterWebAuth2.authenticate(callbackUrlScheme: entangl)
        ↓
getSessionFromUrl(callback)
        ↓
landingRouteAfterAuth()
        ↓
approval | home
```

Comment in code explicitly rejects `signInWithOAuth` system-browser path that caused Site URL / Vercel stickiness.

#### Notifications

| Piece | Status |
|-------|--------|
| Backend path `notifications` → `notify_send_push` → `send-push` → FCM | Live (docs + prior audit) |
| `device_tokens` upsert (Android) | `PushNotificationService` |
| Token lifecycle hooks | Login / signup / push toggle / resume / logout |
| In-app inbox | `NotificationsScreen` + repository |
| Foreground display | `onMessage` → local notifications |
| Flutter does **not** call `activity-push` | Correct for current design |

#### Router (inventory)

| Route | Screen |
|-------|--------|
| `/` | SplashScreen |
| `/login` | LoginScreen |
| `/register` | RegisterScreen |
| `/forgot-password` | ForgotPasswordScreen |
| `/approval-status` | ApprovalStatusScreen |
| `/home` | HomeScreen |
| `/create-post` | CreatePostScreen |
| `/notifications` | NotificationsScreen |
| `/profile` | ProfileScreen (own) |
| `/profile/:userId` | OtherProfileScreen |
| `/profile/edit` | EditProfileScreen |
| `/settings` | SettingsScreen |
| `/settings/privacy` | PrivacySettingsScreen |
| `/admin/requests` | AdminRequestsScreen |

**Session guard:** no session + non-auth page → `/login`.  
Session on `/login` is **not** auto-redirected to home (login decides landing).

#### Navigation call sites (high level)

| Kind | Where |
|------|--------|
| Auth landing `context.go` | splash, login, register, approval, settings logout |
| Main chrome `context.push` | home → create-post, notifications, profile, settings |
| Profile links | post_card, search, follow_list, reactions_sheet → `/profile/:id` |
| Stories | `Navigator.push` to `StoryViewerScreen` (not GoRouter) |
| Sheets / dialogs | `Navigator.pop` for bottom sheets |

---

### VIOLATIONS

Soft / boundary leaks (not “rewrite everything”):

| Severity | Issue | Where |
|----------|--------|--------|
| Medium | `supabase_flutter` imported outside pure data layer | `app_router.dart`, `app_lifecycle.dart`, `splash_screen.dart`, `login_screen.dart`, `auth_provider.dart` (types / session) |
| Medium | Direct `Supabase.instance` session checks | Router redirect, splash, lifecycle refresh |
| Low | UI widgets read `SupabaseService.currentUserId` | `post_card`, `comments_sheet`, `story_viewer`, `story_circles_row`, profile screens |
| Low | `create_post_screen` reads `SupabaseService.currentUserId` | Prefer provider/session helper |
| Low | `SupabaseService` comment says “nothing else imports supabase_flutter” | **Out of date** — several files do |
| Info | Data layer uses Flutter lightly | `foundation.dart` / `services.dart` in repos/services (acceptable for cancel + debug) |

**Not found:**

- Screens issuing raw `.from('table')` PostgREST queries  
- Repositories calling `context.go` / `GoRouter`  
- Domain depending on Flutter widgets  

---

### INCOMPLETE

| Item | Detail | Chunk 1 phase |
|------|--------|----------------|
| **`/post/:id` route** | Does not exist | Phase 4 |
| **NotificationRouter** | Missing | Phase 4 |
| **FCM tap handlers** | No `onMessageOpenedApp` / `getInitialMessage` routing | Phase 4 |
| **Local notification tap** | Payload set; no `onDidReceiveNotificationResponse` router | Phase 4 |
| **In-app notification tap** | Always `context.push('/profile/${actorId}')` — not type-aware | Phase 4 |
| **Structured FCM data contract** | Client does not consume full `type` / `post_id` / `comment_id` | Phase 4 |
| **UNREGISTERED token cleanup** | Documented unfinished | Phase 5 |
| **Duplicate notification inserts** | Known historical dual paths | Phase 5 |
| **Missing profile → Home** | `landingRouteAfterAuth` returns Home if profile null or throws | Phase 3 review |
| **Forgot password in-app complete** | No set-new-password screen; email uses Site URL | Later / auth polish |
| **Inbox Realtime** | Fetch/refresh only | Not Chunk 1 required |
| **iOS FCM** | Intentionally deferred | Out of scope |

---

### RISKS

| Risk | Why it matters |
|------|----------------|
| Notification UX split | Inbox → profile; FCM → no deep route; product feels broken after tap |
| No post destination | Phase 4 cannot finish routing without a post surface |
| Session expiry | No global “401 → login” interceptor; behavior needs Phase 3 verification |
| `landingRouteAfterAuth` catch-all → Home | Can hide missing/corrupt profiles |
| Secrets in `lib/core/secrets.dart` | Security chunk later; wrong URL already caused false offline |
| `main` behind feature tip | Release process must merge deliberately |
| Admin emails hardcoded | `AppConstants.adminEmails` |
| Story viewer outside GoRouter | Deep links to stories harder later |

---

### RECOMMENDATIONS

Ordered for **Chunk 1 only** (do not jump to security/perf mega-work):

1. **Phase 2–3:** Harden auth/session using **existing** Google + landing architecture; define missing-profile behavior explicitly before changing it.  
2. **Phase 4:** Define FCM/inbox **payload contract** → implement `NotificationRouter` → add **post destination** (design first) → wire FCM + inbox taps.  
3. **Phase 5:** Edge `UNREGISTERED` cleanup; investigate duplicate triggers at source.  
4. **Later (not Phase 1):** Route session checks through `SupabaseService` only; reduce UI `currentUserId` reads via providers; fix `SupabaseService` doc comment.  
5. Prefer `flutter analyze lib test` (avoid `build/` noise).

---

### DO NOT CHANGE

| Item | Reason |
|------|--------|
| Google `getOAuthSignInUrl` + `FlutterWebAuth2` + `entangl://` | Device-verified; avoids system-browser / Vercel stick |
| Router: no auto-bounce session from `/login` → `/home` | Login owns approval landing |
| Backend `notifications` as source of truth | FCM is delivery only |
| Edge `send-push` as tray path | Do not reintroduce Flutter → FCM secrets |
| Android-only FCM registration | iOS deferred by product choice |
| Scrap domain / masonry engine | Stable; out of Chunk 1 scope |
| Random new routes without contract | Especially `/post/:id` purpose must be defined in Phase 4 design first |

---

## 1.1 Folder / layer summary

```text
lib/
├── main.dart                 Firebase → FCM handler → Supabase → Push init
├── firebase_options.dart
├── core/                     router, theme, layout, constants, utils
├── data/                     models, repositories, supabase + push services
├── domain/scrap/             pure scrap content (no Flutter)
├── features/                 admin, auth, comments, feed, notifications,
│                             post, profile, scraps, search, settings, stories
└── shared/                   chrome widgets + theme provider
```

**Verdict:** Architecture matches documented direction with **localized boundary leaks**, not a failed layering model.

---

## 1.2 Auth architecture verdict

```text
WORKING + PRESERVE
```

- Email + Google + cancel + approval landing are coherent.  
- Platform schemes match `AppConstants`.  
- Hardening (Phase 2–3) = reliability/tests/edge cases, **not** OAuth redesign.

---

## 1.3 Notification architecture verdict

```text
DELIVERY: WORKING (Android + backend)
UX AFTER TAP: INCOMPLETE
```

- Do **not** rebuild Edge/triggers for Chunk 1 delivery.  
- Complete client routing (Phase 4) and reliability (Phase 5).

---

## 1.4 Router verdict

| Exists | Missing (Phase 4 design) |
|--------|---------------------------|
| Auth, home, create-post, notifications, profile*, settings*, admin | **`/post/:id`** (or equivalent post destination) |
| Story viewer via `Navigator` | Optional later: story GoRoute |

**Phase 1 rule honored:** no `/post/:id` added in this phase.

---

## Direct backend access inventory

| Layer | Pattern | Count / notes |
|-------|---------|----------------|
| Repositories | `SupabaseService.client` / auth / storage | Primary path — **OK** |
| Services | Push upserts `device_tokens` | OK (infra service) |
| Core | Session read/refresh via Supabase | Leak — acceptable short-term |
| Features/UI | `SupabaseService.currentUserId` / session | Convenience leak |
| Features | Raw table queries | **None found** |

---

## Phase 1 acceptance

```text
[x] Layer boundaries inspected
[x] Auth architecture verified
[x] Notification architecture verified
[x] Router inventory completed
[x] Direct backend calls identified
[x] Architecture violations documented
[x] No unnecessary refactor performed
```

---

## Next phase (do not start until reviewed)

**Phase 2 — Authentication hardening**  
Tests and reliability around existing email + Google + approval; preserve OAuth architecture.

---

*Phase 1 deliverable only. Implementation of NotificationRouter / post route belongs in Phase 4.*
