import '../models/notification_model.dart';
import '../services/supabase_service.dart';

class NotificationsRepository {
  final _db = SupabaseService.client;

  static const _select = '''
    *,
    actor:actor_id (id, username, full_name, avatar_url),
    post:post_id   (id, content, image_url)
  ''';

  Future<List<NotificationModel>> getNotifications() async {
    final uid  = SupabaseService.currentUserId!;
    final rows = await _db
        .from('notifications')
        .select(_select)
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((r) => NotificationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return 0;
    final res = await _db
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);
    return (res as List).length;
  }

  Future<void> markAsRead(String id) =>
      _db.from('notifications').update({'is_read': true}).eq('id', id);

  Future<void> markAllAsRead() async {
    final uid = SupabaseService.currentUserId!;
    await _db.from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String id) =>
      _db.from('notifications').delete().eq('id', id);
}
