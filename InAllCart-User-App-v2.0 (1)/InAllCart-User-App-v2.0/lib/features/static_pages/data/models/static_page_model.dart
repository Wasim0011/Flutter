import '../../domain/entities/static_page.dart';

class StaticPageModel extends StaticPage {
  const StaticPageModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.content,
    super.icon,
    required super.order,
  });

  factory StaticPageModel.fromJson(Map<String, dynamic> json) {
    return StaticPageModel(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      content: json['content'] as String,
      icon: json['icon'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }
}
