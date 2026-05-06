import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../../shared/widgets/avatar_widget.dart';

/// Pure display tile. Emits onTap and onDismiss — no logic inside.
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final time     = DateTime.tryParse(notification.createdAt);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: AppColors.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
          color: isUnread ? AppColors.unreadTint : Colors.transparent,
          child: Row(children: [
            if (isUnread)
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              )
            else
              const SizedBox(width: 16),
            AvatarWidget(
                imageUrl: notification.actor?.avatarUrl, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _typeIcon(notification.type),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _text(notification),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.onSurfaceDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    time != null ? timeago.format(time) : '',
                    style: AppTextStyles.timestamp
                        .copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (notification.post?['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  notification.post!['image_url'] as String,
                  width: 44, height: 44, fit: BoxFit.cover),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _typeIcon(NotificationType t) {
    switch (t) {
      case NotificationType.follow:
        return const Icon(Icons.person_add_rounded,
            color: AppColors.primary, size: 14);
      case NotificationType.like:
        return const Icon(Icons.favorite_rounded,
            color: Colors.red, size: 14);
      case NotificationType.dislike:
        return const Icon(Icons.thumb_down_rounded,
            color: Colors.orange, size: 14);
      case NotificationType.comment:
        return const Icon(Icons.chat_bubble_rounded,
            color: Colors.blue, size: 14);
      case NotificationType.reply:
        return const Icon(Icons.reply_rounded,
            color: Colors.green, size: 14);
    }
  }

  String _text(NotificationModel n) {
    final name = n.actor?.fullName ?? 'Someone';
    switch (n.type) {
      case NotificationType.follow:   return '$name started following you';
      case NotificationType.like:     return '$name liked your post';
      case NotificationType.dislike:  return '$name disliked your post';
      case NotificationType.comment:  return '$name commented on your post';
      case NotificationType.reply:    return '$name replied to your comment';
    }
  }
}
