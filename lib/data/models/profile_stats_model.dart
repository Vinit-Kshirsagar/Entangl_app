import 'user_model.dart';

// Extended profile returned by getUserProfile
class ProfileStatsModel {
  final UserModel user;
  final int postCount;
  final int followerCount;
  final int followingCount;
  final bool isFollowing;

  const ProfileStatsModel({
    required this.user,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
  });

  ProfileStatsModel copyWith({
    int? followerCount,
    bool? isFollowing,
  }) =>
      ProfileStatsModel(
        user: user,
        postCount: postCount,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount,
        isFollowing: isFollowing ?? this.isFollowing,
      );
}
