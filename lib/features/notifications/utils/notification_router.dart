import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../models/notification_route_payload.dart';

/// Central decision point for notification taps (inbox + FCM + local).
///
/// Widgets must not invent their own destinations — call [locationFor] /
/// [navigate] only.
class NotificationRouter {
  NotificationRouter._();

  /// Pure path (+ query) for [payload].
  static String locationFor(NotificationRoutePayload payload) {
    final type = payload.type.toLowerCase();
    final actorId = payload.actorId;
    final postId = payload.postId;

    switch (type) {
      case 'follow':
        if (actorId != null && actorId.isNotEmpty) {
          return '/profile/$actorId';
        }
        return AppRoutes.notifications;

      case 'like':
      case 'dislike':
      case 'new_post':
        if (postId != null && postId.isNotEmpty) {
          return AppRoutes.postLocation(postId);
        }
        if (actorId != null && actorId.isNotEmpty) {
          return '/profile/$actorId';
        }
        return AppRoutes.notifications;

      case 'comment':
      case 'reply':
        if (postId != null && postId.isNotEmpty) {
          return AppRoutes.postLocation(
            postId,
            commentId: payload.commentId,
            openComments: true,
          );
        }
        if (actorId != null && actorId.isNotEmpty) {
          return '/profile/$actorId';
        }
        return AppRoutes.notifications;

      default:
        if (postId != null && postId.isNotEmpty) {
          return AppRoutes.postLocation(postId);
        }
        if (actorId != null && actorId.isNotEmpty) {
          return '/profile/$actorId';
        }
        return AppRoutes.notifications;
    }
  }

  /// Push the resolved location onto [router].
  static void navigate(GoRouter router, NotificationRoutePayload payload) {
    final loc = locationFor(payload);
    router.push(loc);
  }
}
