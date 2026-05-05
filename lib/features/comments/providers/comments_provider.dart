import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/repositories/comments_repository.dart';

final commentsRepositoryProvider =
    Provider<CommentsRepository>((_) => CommentsRepository());

class CommentsNotifier
    extends FamilyAsyncNotifier<List<CommentModel>, String> {
  @override
  Future<List<CommentModel>> build(String postId) =>
      ref.read(commentsRepositoryProvider).getComments(postId);

  Future<void> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final comment = await ref
        .read(commentsRepositoryProvider)
        .addComment(postId: postId, content: content, parentId: parentId);

    final current = state.valueOrNull ?? [];
    if (parentId == null) {
      state = AsyncData([...current, comment]);
    } else {
      // Attach reply to parent
      state = AsyncData(current.map((c) {
        if (c.id == parentId) {
          return CommentModel(
            id: c.id, postId: c.postId, userId: c.userId,
            content: c.content, parentId: c.parentId,
            createdAt: c.createdAt, author: c.author,
            replies: [...c.replies, comment],
          );
        }
        return c;
      }).toList());
    }
  }

  Future<void> deleteComment(String commentId,
      {String? parentId}) async {
    await ref
        .read(commentsRepositoryProvider)
        .deleteComment(commentId);

    final current = state.valueOrNull ?? [];
    if (parentId == null) {
      state =
          AsyncData(current.where((c) => c.id != commentId).toList());
    } else {
      state = AsyncData(current.map((c) {
        if (c.id == parentId) {
          return CommentModel(
            id: c.id, postId: c.postId, userId: c.userId,
            content: c.content, parentId: c.parentId,
            createdAt: c.createdAt, author: c.author,
            replies: c.replies
                .where((r) => r.id != commentId)
                .toList(),
          );
        }
        return c;
      }).toList());
    }
  }
}

final commentsProvider = AsyncNotifierProviderFamily<CommentsNotifier,
    List<CommentModel>, String>(CommentsNotifier.new);

/// Input field state — purely UI-facing, no Supabase calls here
class CommentInputState {
  final String  text;
  final String? replyingToId;
  final String? replyingToName;
  final bool    isSubmitting;

  const CommentInputState({
    this.text          = '',
    this.replyingToId,
    this.replyingToName,
    this.isSubmitting  = false,
  });

  CommentInputState copyWith({
    String? text,
    String? replyingToId,
    String? replyingToName,
    bool?   clearReply,
    bool?   isSubmitting,
  }) =>
      CommentInputState(
        text:            text            ?? this.text,
        replyingToId:    clearReply == true ? null : replyingToId ?? this.replyingToId,
        replyingToName:  clearReply == true ? null : replyingToName ?? this.replyingToName,
        isSubmitting:    isSubmitting    ?? this.isSubmitting,
      );
}

class CommentInputNotifier extends Notifier<CommentInputState> {
  @override
  CommentInputState build() => const CommentInputState();

  void setText(String v)  => state = state.copyWith(text: v);
  void clearText()        => state = state.copyWith(text: '');

  void setReplyingTo(String id, String name) =>
      state = state.copyWith(replyingToId: id, replyingToName: name);

  void clearReply() =>
      state = state.copyWith(clearReply: true);

  Future<void> submit(String postId, CommentsNotifier commentsNotifier) async {
    if (state.text.trim().isEmpty || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true);
    try {
      await commentsNotifier.addComment(
        postId:   postId,
        content:  state.text.trim(),
        parentId: state.replyingToId,
      );
      state = const CommentInputState(); // reset
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final commentInputProvider =
    NotifierProvider<CommentInputNotifier, CommentInputState>(
        CommentInputNotifier.new);
