import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../data/community_notifier.dart';
import '../domain/community_models.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(communityPostDetailProvider(postId));
    final commentsAsync = ref.watch(communityCommentsProvider(postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (post) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  // Post body
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Badge(post.category),
                              const Spacer(),
                              Text(
                                post.isAnonymous ? 'Anonymous' : 'Member',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(post.body,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () => ref
                                .read(communityFeedProvider.notifier)
                                .likePost(post.id),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_border,
                                    size: 16, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text('${post.likesCount}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Replies',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  // Comments
                  commentsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Text(
                          'No replies yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        );
                      }
                      return Column(
                        children: comments
                            .map((c) => _CommentTile(comment: c))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            _CommentInput(postId: postId),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.category);
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final CommunityComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(Icons.person_outline,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.isAnonymous ? 'Anonymous' : 'Member',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(comment.body,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends ConsumerStatefulWidget {
  const _CommentInput({required this.postId});
  final String postId;

  @override
  ConsumerState<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<_CommentInput> {
  final _controller = TextEditingController();
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
      await ref
          .read(communityCommentsProvider(widget.postId).notifier)
          .addComment(body: text, isAnonymous: true);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post reply.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Write a reply…',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

