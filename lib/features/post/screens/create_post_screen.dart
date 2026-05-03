import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/supabase_service.dart';
import '../../../features/stories/widgets/create_story_sheet.dart';
import '../../feed/providers/feed_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/create_post_provider.dart';
import '../widgets/create_post_form.dart';

class CreatePostScreen extends ConsumerWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CreatePostState>(createPostProvider, (_, next) {
      if (next.submitted) {
        ref.read(feedProvider.notifier).refresh();
        final uid = SupabaseService.currentUserId;
        if (uid != null) {
          ref.invalidate(profileStatsProvider(uid));
          ref.invalidate(userPostsProvider(uid));
        }
        ref.invalidate(createPostProvider);
        context.pop();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    });

    final state = ref.watch(createPostProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            ref.invalidate(createPostProvider);
            context.pop();
          },
          icon: const Icon(Icons.close_rounded,
              color: AppColors.onSurfaceDark),
        ),
        title: Text('New Post',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.onSurfaceDark)),
        actions: [
          // Story button
          Padding(
            padding:
                const EdgeInsets.only(right: 4, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const CreateStorySheet(),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 5),
                  Text('Story',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primary)),
                ]),
              ),
            ),
          ),
          // Post button — uses canSubmit
          Padding(
            padding: const EdgeInsets.only(
                right: 16, top: 8, bottom: 8),
            child: _PostButton(state: state),
          ),
        ],
      ),
      body: const CreatePostForm(),
    );
  }
}

class _PostButton extends ConsumerWidget {
  final CreatePostState state;
  const _PostButton({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPost = state.canSubmit;
    return GestureDetector(
      onTap: canPost
          ? () => ref.read(createPostProvider.notifier).submit()
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: canPost ? AppColors.primaryGradient : null,
          color: canPost
              ? null
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100),
          boxShadow: canPost
              ? [
                  BoxShadow(
                    color:
                        AppColors.gradientStart.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: state.isSubmitting
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                'Post',
                style: TextStyle(
                  color: canPost
                      ? Colors.white
                      : AppColors.onSurfaceVariantDark
                          .withOpacity(0.3),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
