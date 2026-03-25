import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../profile/domain/profile_notifier.dart';
import '../data/articles_repository.dart';
import '../domain/article.dart';

part 'articles_notifier.g.dart';

// ---------------------------------------------------------------------------
// Category filter — simple StateProvider, no Supabase needed
// ---------------------------------------------------------------------------

@riverpod
class ArticleCategoryFilter extends _$ArticleCategoryFilter {
  @override
  String build() => 'all';

  void setCategory(String category) => state = category;
}

// ---------------------------------------------------------------------------
// Articles list — reacts to profile language + category filter
// ---------------------------------------------------------------------------

@riverpod
Future<List<Article>> articlesList(ArticlesListRef ref) async {
  final category = ref.watch(articleCategoryFilterProvider);
  final profile = await ref.watch(profileNotifierProvider.future);
  final language = profile.language;

  return ref.read(articlesRepositoryProvider).getArticles(
        category: category,
        language: language,
      );
}

// ---------------------------------------------------------------------------
// Single article detail
// ---------------------------------------------------------------------------

@riverpod
Future<Article> articleDetail(ArticleDetailRef ref, String articleId) async {
  final profile = await ref.watch(profileNotifierProvider.future);
  return ref.read(articlesRepositoryProvider).getArticleById(
        id: articleId,
        language: profile.language,
      );
}
