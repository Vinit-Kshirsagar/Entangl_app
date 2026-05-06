import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/users_repository.dart';

// Re-export so widgets only need to import this file
final usersRepositoryProvider =
    Provider<UsersRepository>((_) => UsersRepository());

final searchQueryProvider = StateProvider<String>((_) => '');

/// Debounced search results — derived from the query state.
final searchResultsProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) {
  if (query.trim().isEmpty) return Future.value([]);
  return ref.read(usersRepositoryProvider).searchUsers(query);
});
