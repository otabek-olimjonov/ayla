class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.userId,
    required this.body,
    required this.category,
    required this.isAnonymous,
    required this.likesCount,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String body;
  final String category;
  final bool isAnonymous;
  final int likesCount;
  final DateTime createdAt;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      body: json['body'] as String,
      category: json['category'] as String? ?? 'general',
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      likesCount: json['likes_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    required this.isAnonymous,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String userId;
  final String body;
  final bool isAnonymous;
  final DateTime createdAt;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      body: json['body'] as String,
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
