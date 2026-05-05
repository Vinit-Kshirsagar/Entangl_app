import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../providers/profile_provider.dart';

/// Pure list widget for followers / following tabs.
class FollowList extends ConsumerWidget {
  final String userId;
  final String type; // 'followers' | 'following'
  const FollowList({super.key, required this.userId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo   = ref.read(usersRepositoryProvider);
    final future = type == 'followers'
        ? repo.getFollowers(userId)
        : repo.getFollowing(userId);

    return FutureBuilder(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return Center(
            child: Text('No $type yet',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariantDark)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 120),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            return ListTile(
              leading: AvatarWidget(imageUrl: u.avatarUrl, size: 44),
              title: Text(u.fullName,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.onSurfaceDark)),
              subtitle: Text('@${u.username}',
                  style: AppTextStyles.timestamp),
              onTap: () => context.push('/profile/${u.id}'),
            );
          },
        );
      },
    );
  }
}
