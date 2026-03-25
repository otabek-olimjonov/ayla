import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/community_models.dart';

part 'community_repository.g.dart';

@riverpod
CommunityRepository communityRepository(CommunityRepositoryRef ref) {
  return CommunityRepository(ref.watch(supabaseClientProvider));
}

class CommunityRepository {
  CommunityRepository(this._client);

  final SupabaseClient _client;

  static const _postsTable = 'community_posts';
  static const _commentsTable = 'community_comments';

  // --------------------------------------------------------------------------
  // Posts
  // --------------------------------------------------------------------------

  Future<List<CommunityPost>> getPosts({String? category}) async {
    try {
      var query = _client.from(_postsTable).select();
      if (category != null && category != 'all') {
        query = query.eq('category', category);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<CommunityPost> getPostById(String id) async {
    try {
      final data =
          await _client.from(_postsTable).select().eq('id', id).single();
      return CommunityPost.fromJson(data);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<CommunityPost> createPost({
    required String userId,
    required String body,
    required String category,
    required bool isAnonymous,
  }) async {
    try {
      final data = await _client
          .from(_postsTable)
          .insert({
            'user_id': userId,
            'body': body,
            'category': category,
            'is_anonymous': isAnonymous,
          })
          .select()
          .single();
      return CommunityPost.fromJson(data);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _client.from(_postsTable).delete().eq('id', id);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> likePost(String id) async {
    try {
      await _client.rpc('increment_post_likes', params: {'post_id': id});
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  // --------------------------------------------------------------------------
  // Comments
  // --------------------------------------------------------------------------

  Future<List<CommunityComment>> getComments(String postId) async {
    try {
      final data = await _client
          .from(_commentsTable)
          .select()
          .eq('post_id', postId)
          .order('created_at');
      return (data as List)
          .map((e) => CommunityComment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<CommunityComment> createComment({
    required String postId,
    required String userId,
    required String body,
    required bool isAnonymous,
  }) async {
    try {
      final data = await _client
          .from(_commentsTable)
          .insert({
            'post_id': postId,
            'user_id': userId,
            'body': body,
            'is_anonymous': isAnonymous,
          })
          .select()
          .single();
      return CommunityComment.fromJson(data);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> deleteComment(String id) async {
    try {
      await _client.from(_commentsTable).delete().eq('id', id);
    } catch (_) {
      throw const NetworkFailure();
    }
  }
}
