import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/entangl_app_bar.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final notifier    = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: EntanglAppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.onSurfaceDark, size: 20),
        ),
        title: 'Notifications',
        trailing: TextButton(
          onPressed: notifier.markAllRead,
          child: const Text('Mark all read'),
        ),
      ),
      body: notifsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (notifs) => notifs.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.notifications_none_outlined,
                      color: AppColors.outlineVariant, size: 56),
                  const SizedBox(height: 16),
                  Text("You're all caught up",
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.onSurfaceVariantDark)),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifs.length,
                itemBuilder: (_, i) => NotificationTile(
                  notification: notifs[i],
                  onTap: () {
                    notifier.markRead(notifs[i].id);
                    if (notifs[i].actorId.isNotEmpty) {
                      context.push('/profile/${notifs[i].actorId}');
                    }
                  },
                  onDismiss: () => notifier.remove(notifs[i].id),
                ),
              ),
      ),
    );
  }
}
