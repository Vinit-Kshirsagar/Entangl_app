import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/create_post_provider.dart';

const _maxChars = 500;

class CreatePostForm extends ConsumerStatefulWidget {
  const CreatePostForm({super.key});

  @override
  ConsumerState<CreatePostForm> createState() =>
      _CreatePostFormState();
}

class _CreatePostFormState extends ConsumerState<CreatePostForm> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      ref
          .read(createPostProvider.notifier)
          .setImage(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(createPostProvider);
    final uid     = SupabaseService.currentUserId ?? '';
    final profile =
        ref.watch(ownProfileProvider).valueOrNull;
    final remaining = _maxChars - state.content.length;
    final isNearLimit = remaining <= 50;
    final isOverLimit = remaining < 0;

    return GestureDetector(
      // Dismiss keyboard when tapping outside input
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarWidget(
                    imageUrl: profile?.avatarUrl, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (v) => ref
                        .read(createPostProvider.notifier)
                        .setContent(v),
                    maxLines: null,
                    maxLength: _maxChars,
                    buildCounter: (_, {required currentLength,
                          required isFocused, maxLength}) =>
                        null, // Hide default counter — we draw our own
                    style: const TextStyle(
                      color: AppColors.onSurfaceDark,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        color: AppColors.onSurfaceVariantDark
                            .withOpacity(0.4),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),

            // ── Character counter ──────────────────────────
            if (state.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    left: 56, top: 4, bottom: 8),
                child: Row(children: [
                  const Spacer(),
                  // Circular progress indicator
                  SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      value: state.content.length / _maxChars,
                      strokeWidth: 2.5,
                      backgroundColor:
                          AppColors.outlineVariant.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(
                        isOverLimit
                            ? AppColors.error
                            : isNearLimit
                                ? const Color(0xFFFF8C42)
                                : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      color: isOverLimit
                          ? AppColors.error
                          : isNearLimit
                              ? const Color(0xFFFF8C42)
                              : AppColors.onSurfaceVariantDark
                                  .withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: isNearLimit
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ]),
              ),

            // ── Image preview ──────────────────────────────
            if (state.imageFile != null)
              Stack(children: [
                Container(
                  margin: const EdgeInsets.only(
                      left: 56, top: 8, bottom: 8),
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(state.imageFile!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 16, right: 8,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(createPostProvider.notifier)
                        .clearImage(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ]),

            const SizedBox(height: 8),

            // ── Divider + add photo ────────────────────────
            Container(
              height: 1,
              color: AppColors.outlineVariant.withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 8),
                child: Row(children: [
                  Icon(Icons.photo_library_outlined,
                      color: AppColors.primary.withOpacity(0.8),
                      size: 22),
                  const SizedBox(width: 10),
                  Text('Add photo',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
