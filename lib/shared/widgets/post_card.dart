import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../../data/services/supabase_service.dart';
import '../../features/comments/widgets/comments_sheet.dart';
import '../../features/feed/providers/feed_provider.dart';
import 'avatar_widget.dart';
import 'reactions_sheet.dart';
import 'avatar_viewer_screen.dart';
import 'avatar_viewer_screen.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeCtrl;
  late Animation<double>   _likeScale;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _likeCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() { _likeCtrl.dispose(); super.dispose(); }

  void _animateLike() {
    HapticFeedback.lightImpact();
    _likeCtrl.forward().then((_) => _likeCtrl.reverse());
    ref.read(feedProvider.notifier).toggleLike(widget.post.id);
  }

  void _animateDislike() {
    HapticFeedback.lightImpact();
    ref.read(feedProvider.notifier).toggleDislike(widget.post.id);
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete post?',
            style: TextStyle(
                color: AppColors.onSurfaceDark,
                fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.',
            style: TextStyle(
                color:
                    AppColors.onSurfaceVariantDark.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _deleting = true);
      await ref.read(feedProvider.notifier).deletePost(widget.post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post  = widget.post;
    final isOwn = post.userId == SupabaseService.currentUserId;
    final time  = DateTime.tryParse(post.createdAt);
    final feed  = ref.read(feedProvider.notifier);

    if (_deleting) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.push('/profile/${post.userId}'),
                onLongPress: () {
                  if (post.author?.avatarUrl != null &&
                      post.author!.avatarUrl!.isNotEmpty) {
                    AvatarViewerScreen.show(
                      context,
                      imageUrl: post.author!.avatarUrl!,
                      heroTag: 'avatar_${post.userId}_feed',
                    );
                  }
                },
                child: AvatarWidget(
                  imageUrl: post.author?.avatarUrl,
                  size: 42,
                  heroTag: 'avatar_${post.userId}_feed',
                  onTap: () => context.push('/profile/${post.userId}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/profile/${post.userId}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author?.fullName ?? 'Unknown',
                          style: const TextStyle(
                            color: AppColors.onSurfaceDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          )),
                      const SizedBox(height: 1),
                      Row(children: [
                        Text(
                          '@${post.author?.username ?? ''}',
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '  ·  ${time != null ? timeago.format(time) : ''}',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariantDark
                                .withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              if (isOwn)
                PopupMenuButton<String>(
                  color: AppColors.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  icon: Icon(Icons.more_horiz_rounded,
                      color: AppColors.onSurfaceVariantDark
                          .withOpacity(0.5),
                      size: 20),
                  onSelected: (v) {
                    if (v == 'delete') _confirmDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
            ]),
          ),

          // ── Content ────────────────────────────────────
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(post.content,
                  style: const TextStyle(
                    color: AppColors.onSurfaceDark,
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                  )),
            ),

          // ── Image ───────────────────────────────────────
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 220,
                    color: AppColors.surfaceContainerHigh,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

          // ── Actions ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(children: [
              _ActionChip(
                icon: post.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: post.isLiked
                    ? const Color(0xFFFF4D6D)
                    : AppColors.onSurfaceVariantDark.withOpacity(0.5),
                count: post.likeCount,
                activeColor: const Color(0x1AFF4D6D),
                isActive: post.isLiked,
                onTap: _animateLike,
                scaleAnimation: _likeScale,
              ),
              const SizedBox(width: 4),
              _ActionChip(
                icon: post.isDisliked
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined,
                color: post.isDisliked
                    ? const Color(0xFFFF8C42)
                    : AppColors.onSurfaceVariantDark.withOpacity(0.5),
                count: post.dislikeCount,
                activeColor: const Color(0x1AFF8C42),
                isActive: post.isDisliked,
                onTap: _animateDislike,
              ),
              const SizedBox(width: 4),
              _CommentChip(post: post),
              const Spacer(),
              if (post.likeCount + post.dislikeCount > 0)
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    builder: (_) =>
                        ReactionsSheet(postId: post.id),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(children: [
                      const Text('❤️',
                          style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likeCount + post.dislikeCount}',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariantDark
                              .withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CommentChip extends ConsumerStatefulWidget {
  final PostModel post;
  const _CommentChip({required this.post});

  @override
  ConsumerState<_CommentChip> createState() => _CommentChipState();
}

class _CommentChipState extends ConsumerState<_CommentChip> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.post.commentCount;
  }

  @override
  Widget build(BuildContext context) {
    return _ActionChip(
      icon: Icons.chat_bubble_outline_rounded,
      color: AppColors.onSurfaceVariantDark.withOpacity(0.5),
      count: _count,
      activeColor: Colors.transparent,
      isActive: false,
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CommentsSheet(
          post: widget.post,
          onCommentAdded: () {
            if (mounted) setState(() => _count++);
          },
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData   icon;
  final Color      color;
  final int        count;
  final Color      activeColor;
  final bool       isActive;
  final VoidCallback onTap;
  final Animation<double>? scaleAnimation;

  const _ActionChip({
    required this.icon,
    required this.color,
    required this.count,
    required this.activeColor,
    required this.isActive,
    required this.onTap,
    this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, color: color, size: 19);
    if (scaleAnimation != null) {
      iconWidget =
          ScaleTransition(scale: scaleAnimation!, child: iconWidget);
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(children: [
          iconWidget,
          if (count > 0) ...[
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                color: isActive
                    ? color
                    : AppColors.onSurfaceVariantDark
                        .withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
