import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/profile_stats_model.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../providers/profile_provider.dart';

class ProfileHeader extends ConsumerWidget {
  final ProfileStatsModel stats;
  final bool           isOwn;
  final VoidCallback   onLogout;
  final VoidCallback   onEditProfile;
  final VoidCallback?  onFollowTap;

  const ProfileHeader({
    super.key,
    required this.stats,
    required this.isOwn,
    required this.onLogout,
    required this.onEditProfile,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followState      = ref.watch(followProvider);
    final isFollowing      = isOwn ? false : followState.isFollowing;
    final displayedFollowers =
        stats.followerCount + (isOwn ? 0 : followState.followerDelta);

    // Unique hero tag per user so multiple avatars on screen
    // don't conflict with each other
    final avatarHeroTag = 'avatar_${stats.user.id}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner ───────────────────────────────────────
        Container(
          height: 100,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFFDB2777)],
              begin: Alignment.centerLeft,
              end:   Alignment.centerRight,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar row ─────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.backgroundDark,
                          width: 3,
                        ),
                      ),
                      // heroTag passed so the viewer animates
                      // from exactly this widget
                      child: AvatarWidget(
                        imageUrl: stats.user.avatarUrl,
                        size: 72,
                        heroTag: avatarHeroTag,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isOwn) ...[
                    _OutlineButton(
                      label: 'Edit profile',
                      onTap:  onEditProfile,
                    ),
                    const SizedBox(width: 8),
                    _OutlineButton(
                      label: 'Log out',
                      onTap:  onLogout,
                      isDestructive: true,
                    ),
                  ] else
                    _FollowButton(
                      isFollowing: isFollowing,
                      onTap: onFollowTap,
                    ),
                ],
              ),
              const SizedBox(height: 4),

              Text(stats.user.fullName,
                  style: AppTextStyles.sectionTitle
                      .copyWith(color: AppColors.onSurfaceDark)),
              Text('@${stats.user.username}',
                  style: AppTextStyles.username),

              if (stats.user.bio?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(stats.user.bio!,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariantDark)),
              ],

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(label: 'Posts',     value: stats.postCount),
                    _Stat(
                      label: 'Followers',
                      value: displayedFollowers.clamp(0, 999999999),
                    ),
                    _Stat(label: 'Following', value: stats.followingCount),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool         isFollowing;
  final VoidCallback? onTap;

  const _FollowButton({required this.isFollowing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: isFollowing ? null : const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFFDB2777)],
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
          ),
          border: isFollowing
              ? Border.all(color: AppColors.outlineVariant, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            key: ValueKey(isFollowing),
            style: TextStyle(
              color: isFollowing ? AppColors.onSurfaceDark : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;
  final bool         isDestructive;

  const _OutlineButton({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withOpacity(0.5)
                : AppColors.outlineVariant,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDestructive
                ? AppColors.error
                : AppColors.onSurfaceDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int    value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final display = value >= 1000
        ? '${(value / 1000).toStringAsFixed(1)}k'
        : '$value';
    return Column(children: [
      Text(display,
          style: AppTextStyles.statNumber
              .copyWith(color: AppColors.onSurfaceDark)),
      const SizedBox(height: 4),
      Text(label.toUpperCase(),
          style: AppTextStyles.statLabel
              .copyWith(color: AppColors.onSurfaceVariantDark)),
    ]);
  }
}