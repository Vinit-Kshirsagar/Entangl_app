import 'user_model.dart';

enum StoryMediaType { image, video }

class StoryModel {
  final String         id;
  final String         userId;
  final String         mediaUrl;
  final StoryMediaType mediaType;
  final String         createdAt;
  final UserModel?     author;
  final bool           isViewed;
  final bool           isLiked;
  final int            likeCount;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    this.author,
    this.isViewed  = false,
    this.isLiked   = false,
    this.likeCount = 0,
  });

  factory StoryModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final profileData = json['profiles'];
    UserModel? author;
    if (profileData is Map<String, dynamic>) {
      author = UserModel.fromJson(profileData);
    } else if (profileData is List && profileData.isNotEmpty) {
      author = UserModel.fromJson(
          Map<String, dynamic>.from(profileData.first as Map));
    }

    final views  = (json['story_views']  as List?) ?? [];
    final likes  = (json['story_likes']  as List?) ?? [];

    final isViewed = currentUserId != null &&
        views.any((v) => (v as Map)['viewer_id'] == currentUserId);
    final isLiked  = currentUserId != null &&
        likes.any((l) => (l as Map)['user_id']  == currentUserId);

    return StoryModel(
      id:        json['id']         as String,
      userId:    json['user_id']    as String,
      mediaUrl:  json['media_url']  as String,
      mediaType: (json['media_type'] as String?) == 'video'
          ? StoryMediaType.video
          : StoryMediaType.image,
      createdAt: json['created_at'] as String,
      author:    author,
      isViewed:  isViewed,
      isLiked:   isLiked,
      likeCount: likes.length,
    );
  }

  StoryModel copyWith({bool? isViewed, bool? isLiked, int? likeCount}) =>
      StoryModel(
        id:        id,
        userId:    userId,
        mediaUrl:  mediaUrl,
        mediaType: mediaType,
        createdAt: createdAt,
        author:    author,
        isViewed:  isViewed  ?? this.isViewed,
        isLiked:   isLiked   ?? this.isLiked,
        likeCount: likeCount ?? this.likeCount,
      );
}

class UserStories {
  final UserModel        user;
  final List<StoryModel> stories;
  final bool             allViewed;

  const UserStories({
    required this.user,
    required this.stories,
    required this.allViewed,
  });
}
