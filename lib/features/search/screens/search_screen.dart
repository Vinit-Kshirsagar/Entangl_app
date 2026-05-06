import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../providers/search_provider.dart';

/// SearchDelegate — pure UI. Reads searchResultsProvider only.
class UserSearchDelegate extends SearchDelegate {
  final WidgetRef ref;
  UserSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search users...';

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surfaceContainerLow, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(
            border: InputBorder.none, filled: false,
            hintStyle: TextStyle(color: AppColors.outline)),
      );

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            onPressed: () => query = '',
            icon: const Icon(Icons.clear,
                color: AppColors.onSurfaceVariantDark),
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.onSurfaceDark, size: 20),
      );

  @override
  Widget buildResults(BuildContext context) =>
      _SearchResults(query: query, ref: ref, onTap: (id) {
        close(context, null);
        context.push('/profile/$id');
      });

  @override
  Widget buildSuggestions(BuildContext context) =>
      _SearchResults(query: query, ref: ref, onTap: (id) {
        close(context, null);
        context.push('/profile/$id');
      });
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final WidgetRef ref;
  final ValueChanged<String> onTap;
  const _SearchResults({required this.query, required this.ref, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    if (query.trim().isEmpty) {
      return Center(
        child: Text('Search by name or @username',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariantDark)),
      );
    }
    final async = ref.watch(searchResultsProvider(query));
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('$e')),
      data: (users) => users.isEmpty
          ? Center(
              child: Text('No results for "$query"',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariantDark)))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];
                return ListTile(
                  tileColor: AppColors.backgroundDark,
                  leading: AvatarWidget(imageUrl: u.avatarUrl, size: 44),
                  title: Text(u.fullName,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.onSurfaceDark)),
                  subtitle: Text('@${u.username}',
                      style: AppTextStyles.timestamp),
                  onTap: () => onTap(u.id),
                );
              },
            ),
    );
  }
}
