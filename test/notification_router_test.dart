import 'package:entangl_app/core/router/app_router.dart';
import 'package:entangl_app/data/models/notification_model.dart';
import 'package:entangl_app/features/notifications/models/notification_route_payload.dart';
import 'package:entangl_app/features/notifications/utils/notification_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationRouter.locationFor', () {
    test('follow → profile', () {
      const p = NotificationRoutePayload(
        type: 'follow',
        actorId: 'actor-1',
      );
      expect(NotificationRouter.locationFor(p), '/profile/actor-1');
    });

    test('like / dislike / new_post → post', () {
      expect(
        NotificationRouter.locationFor(
          const NotificationRoutePayload(type: 'like', postId: 'p1'),
        ),
        AppRoutes.postLocation('p1'),
      );
      expect(
        NotificationRouter.locationFor(
          const NotificationRoutePayload(type: 'dislike', postId: 'p2'),
        ),
        '/post/p2',
      );
      expect(
        NotificationRouter.locationFor(
          const NotificationRoutePayload(type: 'new_post', postId: 'p3'),
        ),
        '/post/p3',
      );
    });

    test('comment / reply → post with openComments', () {
      final loc = NotificationRouter.locationFor(
        const NotificationRoutePayload(
          type: 'comment',
          postId: 'p9',
          commentId: 'c1',
        ),
      );
      expect(loc, contains('/post/p9'));
      expect(loc, contains('openComments=1'));
      expect(loc, contains('commentId=c1'));
    });

    test('like without post falls back to actor profile', () {
      expect(
        NotificationRouter.locationFor(
          const NotificationRoutePayload(type: 'like', actorId: 'a1'),
        ),
        '/profile/a1',
      );
    });

    test('empty payload falls back to notifications', () {
      expect(
        NotificationRouter.locationFor(
          const NotificationRoutePayload(type: 'like'),
        ),
        AppRoutes.notifications,
      );
    });
  });

  group('NotificationRoutePayload', () {
    test('fromNotification maps types', () {
      const n = NotificationModel(
        id: 'n1',
        userId: 'u1',
        actorId: 'a1',
        type: NotificationType.reply,
        postId: 'p1',
        commentId: 'c1',
        isRead: false,
        createdAt: '2026-01-01',
      );
      final p = NotificationRoutePayload.fromNotification(n);
      expect(p.type, 'reply');
      expect(p.postId, 'p1');
      expect(p.commentId, 'c1');
      expect(p.openComments, isTrue);
    });

    test('payload string round-trip', () {
      const original = NotificationRoutePayload(
        notificationId: 'n1',
        type: 'follow',
        actorId: 'a1',
      );
      final restored =
          NotificationRoutePayload.fromPayloadString(original.toPayloadString());
      expect(restored.type, 'follow');
      expect(restored.actorId, 'a1');
      expect(restored.notificationId, 'n1');
    });

    test('parses FCM data map', () {
      final p = NotificationRoutePayload.fromRemoteData({
        'type': 'new_post',
        'post_id': 'px',
        'actor_id': 'ax',
      });
      expect(p.type, 'new_post');
      expect(p.postId, 'px');
    });
  });
}
