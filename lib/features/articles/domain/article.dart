/// Maps to the `articles` table.
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isPaid,
    required this.publishedAt,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String body;
  final String category; // 'cycle' | 'pregnancy' | 'nutrition' | 'mental_health'
  final bool isPaid;
  final DateTime publishedAt;
  final String? coverUrl;

  factory Article.fromJson(Map<String, dynamic> json, String language) {
    // Language fallback chain: selected → Russian → Uzbek Latin
    String pick(String field) {
      final langKey = '${field}_$language';
      final ruKey = '${field}_ru';
      final fallbackKey = '${field}_uz';
      final v = json[langKey];
      if (v != null && (v as String).isNotEmpty) return v;
      final ru = json[ruKey];
      if (ru != null && (ru as String).isNotEmpty) return ru;
      return (json[fallbackKey] as String?) ?? '';
    }

    return Article(
      id: json['id'] as String,
      title: pick('title'),
      body: pick('body'),
      category: json['category'] as String? ?? 'cycle',
      isPaid: json['is_paid'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
      coverUrl: json['cover_url'] as String?,
    );
  }
}
