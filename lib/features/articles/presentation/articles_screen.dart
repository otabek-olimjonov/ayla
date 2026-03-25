import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../profile/domain/profile_notifier.dart';
import '../data/articles_notifier.dart';
import '../domain/article.dart';

const _kCategories = [
  ('all', 'All'),
  ('cycle', 'Cycle'),
  ('pregnancy', 'Pregnancy'),
  ('nutrition', 'Nutrition'),
  ('mental_health', 'Mental Health'),
];

class ArticlesScreen extends ConsumerWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(articleCategoryFilterProvider);
    final articlesAsync = ref.watch(articlesListProvider);
    final profileAsync = ref.watch(profileNotifierProvider);
    final isPaid = profileAsync.valueOrNull?.isPaidPlanActive ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.xs,
              ),
              children: _kCategories.map((c) {
                final (value, label) = c;
                final selected = selectedCategory == value;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => ref
                        .read(articleCategoryFilterProvider.notifier)
                        .setCategory(value),
                  ),
                );
              }).toList(),
            ),
          ),
          // Articles list
          Expanded(
            child: articlesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (articles) {
                if (articles.isEmpty) {
                  return const Center(child: Text('No articles yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(articlesListProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: articles.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _ArticleCard(
                      article: articles[i],
                      isPaid: isPaid,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.isPaid});

  final Article article;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final locked = article.isPaid && !isPaid;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked
            ? () => context.push(AppRoutes.paywall)
            : () => context.push(
                  AppRoutes.articleDetail.replaceFirst(':id', article.id),
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.coverUrl != null)
              AspectRatio(
                aspectRatio: 16 / 7,
                child: CachedNetworkImage(
                  imageUrl: article.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.article_outlined,
                        color: AppColors.primary),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style:
                              Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _CategoryBadge(category: article.category),
                      ],
                    ),
                  ),
                  if (locked)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm),
                      child: Icon(Icons.lock_outline,
                          size: 18, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        }).join(' '),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.primary),
      ),
    );
  }
}
