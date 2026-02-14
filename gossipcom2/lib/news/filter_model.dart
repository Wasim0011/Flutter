
class FilterModel {
  final List<String> categories;
  final List<String> regions;
  final List<String> languages;
  final PublishDateFilter publishDate;
  final List<String> sources;
  final bool isTrending;
  final List<String> newsTypes;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const FilterModel({
    this.categories = const [],
    this.regions = const [],
    this.languages = const [],
    this.publishDate = PublishDateFilter.all,
    this.sources = const [],
    this.isTrending = false,
    this.newsTypes = const [],
    this.customStartDate,
    this.customEndDate,
  });

  FilterModel copyWith({
    List<String>? categories,
    List<String>? regions,
    List<String>? languages,
    PublishDateFilter? publishDate,
    List<String>? sources,
    bool? isTrending,
    List<String>? newsTypes,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return FilterModel(
      categories: categories ?? this.categories,
      regions: regions ?? this.regions,
      languages: languages ?? this.languages,
      publishDate: publishDate ?? this.publishDate,
      sources: sources ?? this.sources,
      isTrending: isTrending ?? this.isTrending,
      newsTypes: newsTypes ?? this.newsTypes,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }

  bool get hasActiveFilters {
    return categories.isNotEmpty ||
        regions.isNotEmpty ||
        languages.isNotEmpty ||
        publishDate != PublishDateFilter.all ||
        sources.isNotEmpty ||
        isTrending ||
        newsTypes.isNotEmpty ||
        customStartDate != null ||
        customEndDate != null;
  }

  Map<String, dynamic> toMap() {
    return {
      'categories': categories,
      'regions': regions,
      'languages': languages,
      'publishDate': publishDate.name,
      'sources': sources,
      'isTrending': isTrending,
      'newsTypes': newsTypes,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
    };
  }

  factory FilterModel.fromMap(Map<String, dynamic> map) {
    return FilterModel(
      categories: List<String>.from(map['categories'] ?? []),
      regions: List<String>.from(map['regions'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      publishDate: PublishDateFilter.values.firstWhere(
        (e) => e.name == map['publishDate'],
        orElse: () => PublishDateFilter.all,
      ),
      sources: List<String>.from(map['sources'] ?? []),
      isTrending: map['isTrending'] ?? false,
      newsTypes: List<String>.from(map['newsTypes'] ?? []),
      customStartDate: map['customStartDate'] != null
          ? DateTime.parse(map['customStartDate'])
          : null,
      customEndDate: map['customEndDate'] != null
          ? DateTime.parse(map['customEndDate'])
          : null,
    );
  }

  FilterModel clearAll() {
    return const FilterModel();
  }
}

enum PublishDateFilter {
  all,
  today,
  last24Hours,
  thisWeek,
  custom,
}

class FilterOptions {
  static const List<String> categories = [
    'Politics',
    'Technology',
    'Sports',
    'Business',
    'Entertainment',
    'Science',
    'Health',
    'Lifestyle',
  ];

  static const List<String> regions = [
    'Local',
    'National',
    'International',
  ];

  static const List<String> countries = [
    'India',
    'USA',
    'UK',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'China',
    'Brazil',
  ];

  static const List<String> languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Portuguese',
  ];

  static const List<String> newsTypes = [
    'Articles',
    'Summaries',
    'Videos',
  ];

  static const List<String> commonSources = [
    'BBC',
    'CNN',
    'Reuters',
    'AP News',
    'The Guardian',
    'The Times of India',
    'Hindustan Times',
    'NDTV',
    'India Today',
  ];
}
