class NewsArticleModel {
  final String articleId;
  final String category;
  final String description;
  final String title;
  final String link;
  final String? imageLink;
  final DateTime? publishedAt;
  final String? source;
  final String? language;
  final String? newsType;
  final int? views;
  final int? shares;

  NewsArticleModel({
    required this.articleId,
    required this.category,
    required this.description,
    required this.link,
    required this.title,
    this.imageLink,
    this.publishedAt,
    this.source,
    this.language,
    this.newsType,
    this.views,
    this.shares,
  });

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    return NewsArticleModel(
        articleId: json['article_id']?.toString() ?? "", // Map from JSON
        category: (json['category'] is List && json['category'].isNotEmpty)
            ? json['category'][0]
            : "General",
        title: json['title'] ?? "No title",
        description: json['description'] ?? "No description",
        link: json['link'] ?? "",
        imageLink: json['image_url'] ?? "",
        publishedAt: json['pubDate'] != null 
            ? DateTime.tryParse(json['pubDate']) 
            : null,
        source: json['source_id'] ?? json['source_name'],
        language: json['language'],
        newsType: json['content_type'] ?? 'Articles',
        views: json['views'] ?? 0,
        shares: json['shares'] ?? 0);
  }
}
