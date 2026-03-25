import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/community_repository.dart';
import '../domain/community_models.dart';

part 'community_notifier.g.dart';

// ---------------------------------------------------------------------------
// Category filter
// ---------------------------------------------------------------------------

@riverpod
class CommunityCategory extends _$CommunityCategory {
  @override
  String build() => 'all';
  void set(String c) => state = c;
}

// ---------------------------------------------------------------------------
// Posts feed
// ---------------------------------------------------------------------------

@riverpod
class CommunityFeed extends _$CommunityFeed {
  @override
  Future<List<CommunityPost>> build() async {
    final category = ref.watch(communityCategoryProvider);
    return ref
        .read(communityRepositoryProvider)
        .getPosts(category: category);
  }

  Future<void> refresh() => ref.refresh(communityFeedProvider.future);

  Future<void> addPost({
    required String body,
    required String category,
    required bool isAnonymous,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final post = await ref.read(communityRepositoryProvider).createPost(
          userId: userId,
          body: body,
          category: category,
          isAnonymous: isAnonymous,
        );
    final current = state.valueOrNull ?? [];
    state = AsyncData([post, ...current]);
  }

  Future<void> likePost(String postId) async {
    await ref.read(communityRepositoryProvider).likePost(postId);
    // Optimistically update likes count
    final current = List<CommunityPost>.from(state.valueOrNull ?? []);
    final idx = current.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p = current[idx];
      current[idx] = CommunityPost(
        id: p.id,
        userId: p.userId,
        body: p.body,
        category: p.category,
        isAnonymous: p.isAnonymous,
        likesCount: p.likesCount + 1,
        createdAt: p.createdAt,
      );
      state = AsyncData(current);
    }
  }
}

// ---------------------------------------------------------------------------
// Post detail + comments
// ---------------------------------------------------------------------------

@riverpod
Future<CommunityPost> communityPostDetail(
    CommunityPostDetailRef ref, String postId) async {
  return ref.read(communityRepositoryProvider).getPostById(postId);
}

@riverpod
class CommunityComments extends _$CommunityComments {
  @override
  Future<List<CommunityComment>> build(String postId) async {
    return ref.read(communityRepositoryProvider).getComments(postId);
  }

  Future<void> addComment({
    required String body,
    required bool isAnonymous,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final comment =
        await ref.read(communityRepositoryProvider).createComment(
              postId: postId,
              userId: userId,
              body: body,
              isAnonymous: isAnonymous,
            );
    final current = List<CommunityComment>.from(state.valueOrNull ?? []);
    state = AsyncData([...current, comment]);
  }
}
