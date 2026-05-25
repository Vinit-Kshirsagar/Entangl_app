import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/post_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/widgets/entangl_nav_bar.dart';
import '../../../shared/widgets/post_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/follow_list.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = SupabaseService.currentUserId ?? '';
    return _ProfileScaffold(userId: uid, isOwn: true);
  }
}

class OtherProfileScreen extends ConsumerWidget {
  final String userId;
  const OtherProfileScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwn = userId == (SupabaseService.currentUserId ?? '');
    return _ProfileScaffold(userId: userId, isOwn: isOwn);
  }
}

class _ProfileScaffold extends ConsumerStatefulWidget {
  final String userId;
  final bool   isOwn;
  const _ProfileScaffold({required this.userId, required this.isOwn});

  @override
  ConsumerState<_ProfileScaffold> createState() =>
      _ProfileScaffoldState();
}

class _ProfileScaffoldState extends ConsumerState<_ProfileScaffold>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);

    if (!widget.isOwn) {
      // MUST be in addPostFrameCallback — calling ref in
      // initState before the widget is mounted causes the
      // "dependOnInheritedWidgetOfExactType called before
      // initState completed" error.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Invalidate so we always get fresh isFollowing from DB
        ref.invalidate(profileStatsProvider(widget.userId));
      });
    }
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final statsAsync =
        ref.watch(profileStatsProvider(widget.userId));

    // Init follow state once data arrives
    ref.listen(profileStatsProvider(widget.userId), (_, next) {
      next.whenData((stats) {
        if (!widget.isOwn && stats != null) {
          ref.read(followProvider.notifier)
              .init(stats.isFollowing, widget.userId);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBody: true,
      appBar: widget.isOwn
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
      body: statsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_off_outlined,
                color: AppColors.outlineVariant, size: 48),
            const SizedBox(height: 16),
            Text('Profile not found',
                style: TextStyle(
                    color: AppColors.onSurfaceVariantDark
                        .withOpacity(0.5))),
          ]),
        ),
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text('Profile not found'));
          }
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  stats:  stats,
                  isOwn:  widget.isOwn,
                  onLogout: () async {
                    await ref
                        .read(authNotifierProvider.notifier)
                        .signOut();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  onEditProfile: () =>
                      context.push(AppRoutes.editProfile),
                  onFollowTap: widget.isOwn
                      ? null
                      : () => ref
                          .read(followProvider.notifier)
                          .toggle(),
                  onAdminTap: widget.isOwn &&
                          SupabaseService.client.auth.currentUser?.email ==
                              'rekt11.cam@gmail.com'
                      ? () => context.push(AppRoutes.adminRequests)
                      : null,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedTabBar(TabBar(
                  controller: _tabs,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  labelColor: AppColors.onSurfaceDark,
                  unselectedLabelColor:
                      AppColors.onSurfaceVariantDark
                          .withOpacity(0.4),
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Followers'),
                    Tab(text: 'Following'),
                  ],
                )),
              ),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [
                _PostsTab(userId: widget.userId),
                FollowList(userId: widget.userId, type: 'followers'),
                FollowList(userId: widget.userId, type: 'following'),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: widget.isOwn
          ? EntanglNavBar(
              currentIndex: 2,
              onTap: (i) {
                switch (i) {
                  case 0: context.go(AppRoutes.home); break;
                  case 1: context.push(AppRoutes.createPost); break;
                }
              },
            )
          : null,
    );
  }
}

class _PostsTab extends ConsumerWidget {
  final String userId;
  const _PostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2)),
      error: (_, __) => Center(
          child: Text('Could not load posts',
              style: TextStyle(
                  color: AppColors.onSurfaceVariantDark
                      .withOpacity(0.5)))),
      data: (posts) {
        if (posts.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLow,
            onRefresh: () =>
                ref.refresh(userPostsProvider(userId).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min,
                        children: [
                      Icon(Icons.article_outlined,
                          color: AppColors.outlineVariant
                              .withOpacity(0.5),
                          size: 40),
                      const SizedBox(height: 12),
                      Text('No posts yet',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariantDark
                                  .withOpacity(0.5),
                              fontSize: 14)),
                    ]),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainerLow,
          onRefresh: () =>
              ref.refresh(userPostsProvider(userId).future),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.only(top: 8, bottom: 120),
            itemCount: posts.length,
            itemBuilder: (_, i) =>
                PostCard(post: posts[i] as PostModel),
          ),
        );
      },
    );
  }
}

class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _PinnedTabBar(this.tabBar);
  @override
  Widget build(_, __, ___) =>
      Container(color: AppColors.backgroundDark, child: tabBar);
  @override double get maxExtent => tabBar.preferredSize.height;
  @override double get minExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(_) => false;
}
