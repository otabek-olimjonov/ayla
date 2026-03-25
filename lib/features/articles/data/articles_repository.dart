import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/article.dart';

part 'articles_repository.g.dart';

@riverpod
ArticlesRepository articlesRepository(ArticlesRepositoryRef ref) {
  return ArticlesRepository(ref.watch(supabaseClientProvider));
}

class ArticlesRepository {
  ArticlesRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'articles';

  /// Fetches all published articles, optionally filtered by [category].
  /// [language] drives the title/body column selection + fallback.
  Future<List<Article>> getArticles({
    String? category,
    required String language,
  }) async {
    try {
      var query = _client.from(_table).select();

      if (category != null && category != 'all') {
        query = query.eq('category', category);
      }

      final data = await query.order('published_at', ascending: false);

      return (data as List)
          .map((e) => Article.fromJson(e as Map<String, dynamic>, language))
          .toList();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  /// Fetches a single article by [id].
  Future<Article> getArticleById({
    required String id,
    required String language,
  }) async {
    try {
      final data = await _client.from(_table).select().eq('id', id).single();
      return Article.fromJson(data, language);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundFailure();
      throw const NetworkFailure();
    } catch (_) {
      throw const NetworkFailure();
    }
  }
}
