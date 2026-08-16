# Phase 4 — Notification routing

**Date:** 2026-08-13  
**Branch:** `feature/production-readiness`

## Contract (FCM `data` + local payload JSON)

```json
{
  "notification_id": "uuid?",
  "type": "like|dislike|comment|reply|follow|new_post",
  "actor_id": "uuid?",
  "post_id": "uuid?",
  "comment_id": "uuid?"
}
```

Edge `send-push` should populate these keys on the FCM **data** map (in addition to notification title/body).  
Repo source (`supabase/functions/send-push`) sends them after Phase 5 — **deploy** that function if not already updated.

## Client map

| Type | Destination |
|------|-------------|
| follow | `/profile/{actor_id}` |
| like / dislike / new_post | `/post/{post_id}` |
| comment / reply | `/post/{post_id}?openComments=1&commentId=…` |
| missing ids | profile fallback → else `/notifications` |

## Files

| Path | Role |
|------|------|
| `notification_route_payload.dart` | Parse/serialize contract |
| `notification_router.dart` | Pure location + `GoRouter.push` |
| `post_detail_screen.dart` | `/post/:postId` UI |
| `PostsRepository.getPostById` | Load single post |
| `PushNotificationService` | Open handlers + JSON local payload |
| Inbox `NotificationsScreen` | Same router as FCM |

## Open paths wired

- `FirebaseMessaging.onMessageOpenedApp` (background)
- `getInitialMessage` (terminated)
- Local notification `onDidReceiveNotificationResponse` (foreground banner tap)
- In-app notification list tap

## Manual test matrix

| Type | Inbox tap | FCM tap |
|------|-----------|---------|
| like | post | post |
| follow | profile | profile |
| comment | post + comments sheet | post + comments sheet |
| deleted post | “Post unavailable” | same |
