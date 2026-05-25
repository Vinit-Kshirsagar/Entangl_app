import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/story_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../providers/stories_provider.dart';
import '../screens/story_viewer_screen.dart';

class StoryCirclesRow extends ConsumerWidget {
  const StoryCirclesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return storiesAsync.when(
      loading: () => const _SkeletonRow(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (userStories) {
        if (userStories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: userStories.length,
            itemBuilder: (_, i) {
              final us = userStories[i];
              return _StoryCircle(
                userStory: us,
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => StoryViewerScreen(
                      allUserStories:   userStories,
                      initialUserIndex: i,
                    ),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration:
                        const Duration(milliseconds: 180),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final UserStories  userStory;
  final VoidCallback onTap;

  const _StoryCircle({required this.userStory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOwn   = userStory.user.id == SupabaseService.currentUserId;
    final viewed  = userStory.allViewed;
    final name    = isOwn
        ? 'Your story'
        : userStory.user.fullName.split(' ').first;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ring + avatar — no overlapping elements
            Stack(
              alignment: Alignment.center,
              children: [
                // Gradient or muted ring
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: viewed
                        ? null
                        : AppColors.primaryGradient,
                    color: viewed
                        ? AppColors.outlineVariant.withOpacity(0.35)
                        : null,
                  ),
                ),
                // White gap ring
                Container(
                  width: 57, height: 57,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundDark,
                  ),
                ),
                // Avatar — onTap overrides default avatar viewer
                AvatarWidget(
                  imageUrl: userStory.user.avatarUrl,
                  size: 52,
                  onTap: onTap,
                ),
                // Add badge — bottom right only for own story
                if (isOwn)
                  Positioned(
                    bottom: 0, right: 2,
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        color: AppColors.backgroundDark,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              name,
              style: TextStyle(
                color: viewed
                    ? AppColors.onSurfaceVariantDark.withOpacity(0.45)
                    : AppColors.onSurfaceDark,
                fontSize: 11,
                fontWeight:
                    viewed ? FontWeight.w400 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatefulWidget {
  const _SkeletonRow();
  @override
  State<_SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<_SkeletonRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 5,
          itemBuilder: (_, __) {
            final color = Color.lerp(
              AppColors.surfaceContainerHigh,
              AppColors.surfaceContainerLow,
              _anim.value,
            )!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 38, height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
