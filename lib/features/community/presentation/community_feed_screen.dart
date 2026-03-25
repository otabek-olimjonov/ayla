import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../profile/domain/profile_notifier.dart';
import '../data/community_notifier.dart';
import '../domain/community_models.dart';
import 'post_detail_screen.dart';

const _kCategories = [
  ('all', 'All'),
  ('general', 'General'),
  ('pregnancy', 'Pregnancy'),
  ('symptoms', 'Symptoms'),
  ('advice', 'Advice'),
];

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(communityCategoryProvider);
    final postsAsync = ref.watch(communityFeedProvider);
    final isPaid = ref.watch(profileNotifierProvider).valueOrNull?.isPaidPlanActive ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      floatingActionButton: isPaid
          ? FloatingActionButton(
              onPressed: () => _showCreatePost(context, ref),
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.xs),
              children: _kCategories.map((c) {
                final (value, label) = c;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(label),
                    selected: selectedCategory == value,
                    onSelected: (_) =>
                        ref.read(communityCategoryProvider.notifier).set(value),
                  ),
                );
              }).toList(),
            ),
          ),
          // Posts
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet. Be the first!'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(communityFeedProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _PostCard(
                      post: posts[i],
                      currentUserId: '',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PostDetailScreen(postId: posts[i].id),
                        ),
                      ),
                      onLike: () => ref
                          .read(communityFeedProvider.notifier)
                          .likePost(posts[i].id),
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

  void _showCreatePost(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CreatePostSheet(ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Post card
// ---------------------------------------------------------------------------

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onTap,
    required this.onLike,
  });

  final CommunityPost post;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryBadge(category: post.category),
                  const Spacer(),
                  Text(
                    post.isAnonymous ? 'Anonymous' : 'Member',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(post.body,
                  style: theme.textTheme.bodyMedium, maxLines: 4),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  GestureDetector(
                    onTap: onLike,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border,
                            size: 16, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text('${post.likesCount}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.chat_bubble_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('View replies',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
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
        '${category[0].toUpperCase()}${category.substring(1)}',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create post bottom sheet
// ---------------------------------------------------------------------------

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _controller = TextEditingController();
  String _category = 'general';
  bool _anonymous = true;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(communityFeedProvider.notifier).addPost(
            body: text,
            category: _category,
            isAnonymous: _anonymous,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('New post',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share with the community…',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('General')),
              DropdownMenuItem(value: 'pregnancy', child: Text('Pregnancy')),
              DropdownMenuItem(value: 'symptoms', child: Text('Symptoms')),
              DropdownMenuItem(value: 'advice', child: Text('Advice')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'general'),
          ),
          SwitchListTile(
            title: const Text('Post anonymously'),
            value: _anonymous,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _anonymous = v),
          ),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Colors.white),
                  )
                : const Text('Post'),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

