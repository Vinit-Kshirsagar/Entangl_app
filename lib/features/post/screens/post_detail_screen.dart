import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/entangl_colors.dart';
import '../../../data/models/post_model.dart';
import '../../../shared/widgets/post_card.dart';
import '../../comments/widgets/comments_sheet.dart';
import '../../feed/providers/feed_provider.dart';

/// Destination for notification deep links: `/post/:postId`.
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  final String? commentId;
  final bool openComments;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.commentId,
    this.openComments = false,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late Future<PostModel?> _future;
  bool _openedComments = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(postsRepositoryProvider).getPostById(widget.postId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = ref.read(postsRepositoryProvider).getPostById(widget.postId);
      _openedComments = false;
    });
  }

  void _maybeOpenComments(PostModel post) {
    if (_openedComments || !widget.openComments) return;
    _openedComments = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CommentsSheet(post: post),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new, color: palette.onSurface, size: 20),
        ),
        title: Text(
          'Post',
          style: AppTextStyles.title2.copyWith(color: palette.onSurface),
        ),
      ),
      body: FutureBuilder<PostModel?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: palette.primary,
                strokeWidth: 2,
              ),
            );
          }

          if (snap.hasError) {
            return _Message(
              title: 'Could not load post',
              body: 'Check your connection and try again.',
              onRetry: _reload,
            );
          }

          final post = snap.data;
          if (post == null) {
            return const _Message(
              title: 'Post unavailable',
              body: 'This post may have been deleted.',
            );
          }

          _maybeOpenComments(post);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                PostCard(post: post),
                if (widget.commentId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      'Opened from a comment notification',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const _Message({
    required this.title,
    required this.body,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 48, color: palette.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.title1.copyWith(color: palette.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: palette.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
