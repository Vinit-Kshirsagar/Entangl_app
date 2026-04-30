import 'user_model.dart';

class PostModel {
  final String  id;
  final String  userId;
  final String  content;
  final String? imageUrl;
  final String  createdAt;
  final UserModel? author;
  final int  likeCount;
  final int  dislikeCount;
  final int  commentCount;
  final bool isLiked;
  final bool isDisliked;

  const PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.author,
    this.likeCount    = 0,
    this.dislikeCount = 0,
    this.commentCount = 0,
    this.isLiked      = false,
    this.isDisliked   = false,
  });

  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    // profiles can come back as a Map or a List depending on Supabase version
    final profileData = json['profiles'];
    UserModel? author;
    if (profileData is Map<String, dynamic>) {
      author = UserModel.fromJson(profileData);
    } else if (profileData is List && profileData.isNotEmpty) {
      author = UserModel.fromJson(
          Map<String, dynamic>.from(profileData.first as Map));
    }

    final likes    = (json['likes']    as List?) ?? [];
    final dislikes = (json['dislikes'] as List?) ?? [];
    final comments = (json['comments'] as List?) ?? [];

    return PostModel(
      id:           json['id']         as String,
      userId:       json['user_id']    as String,
      content:      json['content']    as String,
      imageUrl:     json['image_url']  as String?,
      createdAt:    json['created_at'] as String,
      author:       author,
      likeCount:    likes.length,
      dislikeCount: dislikes.length,
      commentCount: comments.length,
      isLiked: currentUserId != null &&
          likes.any((l) => (l as Map)['user_id'] == currentUserId),
      isDisliked: currentUserId != null &&
          dislikes.any((d) => (d as Map)['user_id'] == currentUserId),
    );
  }

  PostModel copyWith({
    int?  likeCount,
    int?  dislikeCount,
    int?  commentCount,
    bool? isLiked,
    bool? isDisliked,
  }) =>
      PostModel(
        id:           id,
        userId:       userId,
        content:      content,
        imageUrl:     imageUrl,
        createdAt:    createdAt,
        author:       author,
        likeCount:    likeCount    ?? this.likeCount,
        dislikeCount: dislikeCount ?? this.dislikeCount,
        commentCount: commentCount ?? this.commentCount,
        isLiked:      isLiked      ?? this.isLiked,
        isDisliked:   isDisliked   ?? this.isDisliked,
      );
}