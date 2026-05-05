import '../models/comment_model.dart';
import '../services/supabase_service.dart';

class CommentsRepository {
  final _db = SupabaseService.client;

  static const _select = '''
    *,
    profiles!user_id (id, username, full_name, avatar_url),
    replies:comments!parent_id (
      *,
      profiles!user_id (id, username, full_name, avatar_url)
    )
  ''';

  Future<List<CommentModel>> getComments(String postId) async {
    final rows = await _db
        .from('comments')
        .select(_select)
        .eq('post_id', postId)
        .isFilter('parent_id', null)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) => CommentModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final uid = SupabaseService.currentUserId!;
    final row = await _db.from('comments').insert({
      'user_id': uid,
      'post_id': postId,
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    }).select('*, profiles!user_id (id, username, full_name, avatar_url)')
        .single();
    return CommentModel.fromJson(row as Map<String, dynamic>);
  }

  Future<void> deleteComment(String commentId) =>
      _db.from('comments').delete().eq('id', commentId);
}
