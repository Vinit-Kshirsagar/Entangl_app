import 'user_model.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String? parentId;
  final String createdAt;
  final UserModel? author;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.parentId,
    required this.createdAt,
    this.author,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'];
    UserModel? author;
    if (profileData is Map<String, dynamic>) {
      author = UserModel.fromJson(profileData);
    } else if (profileData is List && profileData.isNotEmpty) {
      author = UserModel.fromJson(profileData.first as Map<String, dynamic>);
    }

    final rawReplies =
        (json['replies'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      parentId: json['parent_id'] as String?,
      createdAt: json['created_at'] as String,
      author: author,
      replies: rawReplies.map((r) => CommentModel.fromJson(r)).toList(),
    );
  }
}
