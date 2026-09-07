import 'package:equatable/equatable.dart';

class StaticPage extends Equatable {
  final int id;
  final String title;
  final String slug;
  final String content; // HTML
  final String? icon;
  final int order;

  const StaticPage({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.icon,
    required this.order,
  });

  @override
  List<Object?> get props => [id, slug];
}
