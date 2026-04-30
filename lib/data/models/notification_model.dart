import 'user_model.dart';

enum NotificationType { follow, like, dislike, comment, reply }

class NotificationModel {
  final String id;
  final String userId;
  final String actorId;
  final NotificationType type;
  final String? postId;
  final String? commentId;
  final bool isRead;
  final String createdAt;
  final UserModel? actor;
  final Map<String, dynamic>? post;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.postId,
    this.commentId,
    required this.isRead,
    required this.createdAt,
    this.actor,
    this.post,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actorData = json['actor'];
    UserModel? actor;
    if (actorData is Map<String, dynamic>) {
      actor = UserModel.fromJson(actorData);
    } else if (actorData is List && actorData.isNotEmpty) {
      actor = UserModel.fromJson(actorData.first as Map<String, dynamic>);
    }

    final postData = json['post'];
    Map<String, dynamic>? post;
    if (postData is Map<String, dynamic>) {
      post = postData;
    } else if (postData is List && postData.isNotEmpty) {
      post = postData.first as Map<String, dynamic>;
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      type: _parseType(json['type'] as String),
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      isRead: json['is_read'] as bool,
      createdAt: json['created_at'] as String,
      actor: actor,
      post: post,
    );
  }

  static NotificationType _parseType(String t) {
    switch (t) {
      case 'follow':  return NotificationType.follow;
      case 'like':    return NotificationType.like;
      case 'dislike': return NotificationType.dislike;
      case 'comment': return NotificationType.comment;
      case 'reply':   return NotificationType.reply;
      default:        return NotificationType.like;
    }
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        actorId: actorId,
        type: type,
        postId: postId,
        commentId: commentId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        actor: actor,
        post: post,
      );
}
