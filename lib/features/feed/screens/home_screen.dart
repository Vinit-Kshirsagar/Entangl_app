import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/post_model.dart';
import '../../../features/stories/widgets/story_circles_row.dart';
import '../../../shared/widgets/entangl_nav_bar.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/post_card.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../search/screens/search_screen.dart';
import '../providers/feed_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBody: true,
      body: const _HomeBody(),
      bottomNavigationBar: EntanglNavBar(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1: context.push(AppRoutes.createPost); break;
            case 2: context.push(AppRoutes.profile); break;
          }
        },
      ),
    );
  }
}

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody();

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final top       = MediaQuery.of(context).padding.top;
    final feedAsync = ref.watch(feedProvider);

    // Header height: status bar + name row (52) + stories (96) + divider (1)
    final headerHeight = top + 52.0 + 96.0 + 1.0;

    return CustomScrollView(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Floating header — scrolls away, snaps back on scroll up
        SliverAppBar(
          backgroundColor: AppColors.backgroundDark,
          floating:       true,
          snap:           true,
          pinned:         false,
          elevation:      0,
          toolbarHeight:  0,
          expandedHeight: headerHeight,
          flexibleSpace: FlexibleSpaceBar(
            background: ClipRect(  // prevents any pixel overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status bar spacer
                  SizedBox(height: top + 10),
                  // Top bar: Entangl + search + bell
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20, right: 8, bottom: 4),
                    child: Row(children: [
                      GradientText(
                        'Entangl',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      _SearchButton(),
                      _NotifBell(),
                    ]),
                  ),
                  // Stories row — fixed height 96
                  const SizedBox(
                    height: 96,
                    child: StoryCirclesRow(),
                  ),
                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: AppColors.outlineVariant.withOpacity(0.08),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Feed content
        feedAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.wifi_off_rounded,
                      color: AppColors.error, size: 32),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => ref.refresh(feedProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text('Retry',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),
          data: (posts) => posts.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min,
                        children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 20),
                      const Text('Nothing here yet',
                          style: TextStyle(
                            color: AppColors.onSurfaceDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 8),
                      Text('Be the first to post something',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariantDark
                                .withOpacity(0.5),
                            fontSize: 14,
                          )),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () =>
                            context.push(AppRoutes.createPost),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius:
                                BorderRadius.circular(100),
                          ),
                          child: const Text('Create post',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              )),
                        ),
                      ),
                    ]),
                  ),
                )
              : SliverPadding(
                  padding:
                      const EdgeInsets.only(top: 4, bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        if (i == posts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        }
                        return PostCard(
                            post: posts[i] as PostModel);
                      },
                      childCount: posts.length + 1,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SearchButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => showSearch(
        context: context,
        delegate: UserSearchDelegate(ref),
      ),
      icon: const Icon(Icons.search_rounded,
          color: AppColors.onSurfaceVariantDark, size: 22),
    );
  }
}

class _NotifBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(unreadCountProvider).valueOrNull ?? 0;
    return Stack(children: [
      IconButton(
        onPressed: () => context.push(AppRoutes.notifications),
        icon: const Icon(Icons.notifications_outlined,
            color: AppColors.onSurfaceVariantDark, size: 22),
      ),
      if (count > 0)
        Positioned(
          right: 8, top: 8,
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientStart.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
    ]);
  }
}
