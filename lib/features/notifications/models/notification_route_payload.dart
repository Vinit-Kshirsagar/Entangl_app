import 'dart:convert';

import '../../../data/models/notification_model.dart';

/// Structured routing data shared by FCM data payloads and in-app inbox rows.
///
/// Contract (string values in FCM `data` map):
/// ```json
/// {
///   "notification_id": "uuid",
///   "type": "like|dislike|comment|reply|follow|new_post",
///   "actor_id": "uuid",
///   "post_id": "uuid?",
///   "comment_id": "uuid?"
/// }
/// ```
class NotificationRoutePayload {
  final String? notificationId;
  final String type;
  final String? actorId;
  final String? postId;
  final String? commentId;

  const NotificationRoutePayload({
    this.notificationId,
    required this.type,
    this.actorId,
    this.postId,
    this.commentId,
  });

  static const supportedTypes = {
    'like',
    'dislike',
    'comment',
    'reply',
    'follow',
    'new_post',
  };

  bool get openComments => type == 'comment' || type == 'reply';

  factory NotificationRoutePayload.fromMap(Map<String, dynamic> map) {
    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    return NotificationRoutePayload(
      notificationId: s(map['notification_id'] ?? map['id']),
      type: (s(map['type']) ?? 'like').toLowerCase(),
      actorId: s(map['actor_id']),
      postId: s(map['post_id']),
      commentId: s(map['comment_id']),
    );
  }

  /// FCM `message.data` is `Map<String, String>`.
  factory NotificationRoutePayload.fromRemoteData(Map<String, dynamic> data) =>
      NotificationRoutePayload.fromMap(data);

  factory NotificationRoutePayload.fromNotification(NotificationModel n) {
    return NotificationRoutePayload(
      notificationId: n.id,
      type: _typeToString(n.type),
      actorId: n.actorId,
      postId: n.postId,
      commentId: n.commentId,
    );
  }

  factory NotificationRoutePayload.fromPayloadString(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const NotificationRoutePayload(type: 'like');
    }
    final text = raw.trim();
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return NotificationRoutePayload.fromMap(decoded);
      }
      if (decoded is Map) {
        return NotificationRoutePayload.fromMap(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {
      // Legacy: bare post id or route path
      if (text.startsWith('/')) {
        return NotificationRoutePayload.fromMap({'route': text, 'type': 'like'});
      }
      // UUID-ish post id only
      return NotificationRoutePayload(type: 'like', postId: text);
    }
    return const NotificationRoutePayload(type: 'like');
  }

  Map<String, String> toDataMap() {
    final m = <String, String>{'type': type};
    if (notificationId != null) m['notification_id'] = notificationId!;
    if (actorId != null) m['actor_id'] = actorId!;
    if (postId != null) m['post_id'] = postId!;
    if (commentId != null) m['comment_id'] = commentId!;
    return m;
  }

  String toPayloadString() => jsonEncode(toDataMap());

  static String _typeToString(NotificationType t) {
    switch (t) {
      case NotificationType.follow:
        return 'follow';
      case NotificationType.like:
        return 'like';
      case NotificationType.dislike:
        return 'dislike';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.reply:
        return 'reply';
      case NotificationType.newPost:
        return 'new_post';
    }
  }
}
