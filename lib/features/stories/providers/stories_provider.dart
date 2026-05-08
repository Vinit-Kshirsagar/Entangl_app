import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/story_model.dart';
import '../../../data/repositories/stories_repository.dart';

final storiesRepositoryProvider =
    Provider<StoriesRepository>((_) => StoriesRepository());

class StoriesNotifier extends AsyncNotifier<List<UserStories>> {
  @override
  Future<List<UserStories>> build() =>
      ref.read(storiesRepositoryProvider).getActiveStories();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(storiesRepositoryProvider).getActiveStories());
  }

  Future<void> markViewed(String storyId) async {
    await ref.read(storiesRepositoryProvider).markViewed(storyId);
    _updateStory(storyId, (s) => s.copyWith(isViewed: true));
  }

  Future<void> toggleLike(String storyId) async {
    final story = _findStory(storyId);
    if (story == null) return;

    // Optimistic
    final nowLiked = !story.isLiked;
    _updateStory(
      storyId,
      (s) => s.copyWith(
        isLiked:   nowLiked,
        likeCount: nowLiked ? s.likeCount + 1 : s.likeCount - 1,
      ),
    );

    try {
      final repo = ref.read(storiesRepositoryProvider);
      nowLiked
          ? await repo.likeStory(storyId)
          : await repo.unlikeStory(storyId);
    } catch (_) {
      // Revert
      _updateStory(
        storyId,
        (s) => s.copyWith(
          isLiked:   story.isLiked,
          likeCount: story.likeCount,
        ),
      );
    }
  }

  Future<void> deleteStory(String storyId) async {
    await ref.read(storiesRepositoryProvider).deleteStory(storyId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current
        .map((us) => UserStories(
              user:      us.user,
              stories:   us.stories.where((s) => s.id != storyId).toList(),
              allViewed: us.allViewed,
            ))
        .where((us) => us.stories.isNotEmpty)
        .toList());
  }

  StoryModel? _findStory(String storyId) {
    for (final us in state.valueOrNull ?? []) {
      for (final s in us.stories) {
        if (s.id == storyId) return s;
      }
    }
    return null;
  }

  void _updateStory(String storyId, StoryModel Function(StoryModel) update) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((us) {
      final updatedStories = us.stories.map((s) {
        if (s.id != storyId) return s;
        return update(s);
      }).toList();
      final allViewed = updatedStories.every((s) => s.isViewed);
      return UserStories(
          user: us.user, stories: updatedStories, allViewed: allViewed);
    }).toList());
  }
}

final storiesProvider =
    AsyncNotifierProvider<StoriesNotifier, List<UserStories>>(
        StoriesNotifier.new);

// Create story state
class CreateStoryState {
  final File?          file;
  final StoryMediaType mediaType;
  final bool           isUploading;
  final String?        error;
  final bool           uploaded;

  const CreateStoryState({
    this.file,
    this.mediaType   = StoryMediaType.image,
    this.isUploading = false,
    this.error,
    this.uploaded    = false,
  });

  CreateStoryState copyWith({
    File?          file,
    StoryMediaType? mediaType,
    bool?          isUploading,
    String?        error,
    bool?          uploaded,
  }) =>
      CreateStoryState(
        file:        file        ?? this.file,
        mediaType:   mediaType   ?? this.mediaType,
        isUploading: isUploading ?? this.isUploading,
        error:       error,
        uploaded:    uploaded    ?? this.uploaded,
      );
}

class CreateStoryNotifier extends Notifier<CreateStoryState> {
  @override
  CreateStoryState build() => const CreateStoryState();

  void setFile(File f, StoryMediaType type) =>
      state = state.copyWith(file: f, mediaType: type);

  Future<void> upload() async {
    if (state.file == null || state.isUploading) return;
    state = state.copyWith(isUploading: true);
    try {
      await ref.read(storiesRepositoryProvider).createStory(
            file:      state.file!,
            mediaType: state.mediaType,
          );
      ref.read(storiesProvider.notifier).refresh();
      state = state.copyWith(isUploading: false, uploaded: true);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }
}

final createStoryProvider =
    NotifierProvider<CreateStoryNotifier, CreateStoryState>(
        CreateStoryNotifier.new);
