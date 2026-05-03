import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/feed/providers/feed_provider.dart';
import '../widgets/avatar_widget.dart';

/// Pure UI sheet — fetches reactions via FutureProvider, no direct repo calls.
class ReactionsSheet extends ConsumerWidget {
  final String postId;
  const ReactionsSheet({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const TabBar(
              tabs: [Tab(text: 'Likes ❤️'), Tab(text: 'Dislikes 👎')],
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceVariantDark,
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  _ReactionsTab(postId: postId, type: 'likes'),
                  _ReactionsTab(postId: postId, type: 'dislikes'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Provider to fetch reactions lazily
final _likesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, postId) =>
        ref.read(postsRepositoryProvider).getPostLikes(postId));

final _dislikesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, postId) =>
        ref.read(postsRepositoryProvider).getPostDislikes(postId));

class _ReactionsTab extends ConsumerWidget {
  final String postId;
  final String type;
  const _ReactionsTab({required this.postId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = type == 'likes'
        ? ref.watch(_likesProvider(postId))
        : ref.watch(_dislikesProvider(postId));

    return async.when(
      loading: () => const Center(
          child:
              CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) => items.isEmpty
          ? Center(
              child: Text('No $type yet',
                  style: const TextStyle(
                      color: AppColors.onSurfaceVariantDark)))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p       = items[i]['profiles'];
                final profile = p is List
                    ? p.first as Map
                    : p as Map;
                return ListTile(
                  leading: AvatarWidget(
                      imageUrl: profile['avatar_url'] as String?,
                      size: 40),
                  title: Text(
                    profile['full_name'] as String? ?? '',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.onSurfaceDark),
                  ),
                  subtitle: Text('@${profile['username'] ?? ''}',
                      style: AppTextStyles.timestamp),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                        '/profile/${profile['id']}');
                  },
                );
              },
            ),
    );
  }
}
