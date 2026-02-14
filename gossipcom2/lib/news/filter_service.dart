import 'dart:async';
import 'package:gossipcom/news/filter_model.dart';
import 'package:gossipcom/news/news_model.dart';

class FilterService {
  static Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  /// Filters news articles based on active filters
  static List<NewsArticleModel> filterNews(
    List<NewsArticleModel> articles,
    FilterModel filters,
  ) {
    if (!filters.hasActiveFilters) {
      return articles;
    }

    return articles.where((article) {
      // Category filter
      if (filters.categories.isNotEmpty) {
        final articleCategory = article.category.toLowerCase();
        final hasMatchingCategory = filters.categories.any(
          (filterCategory) => articleCategory.contains(filterCategory.toLowerCase()),
        );
        if (!hasMatchingCategory) return false;
      }

      // Language filter (if available in article)
      if (filters.languages.isNotEmpty) {
        // Assuming language is stored in article data
        // This would need to be added to NewsArticleModel if not present
        // For now, we'll skip this filter
      }

      // Publish date filter
      if (filters.publishDate != PublishDateFilter.all) {
        final now = DateTime.now();
        final articleDate = article.publishedAt ?? now;
        
        switch (filters.publishDate) {
          case PublishDateFilter.today:
            if (!_isSameDay(articleDate, now)) return false;
            break;
          case PublishDateFilter.last24Hours:
            if (now.difference(articleDate).inHours > 24) return false;
            break;
          case PublishDateFilter.thisWeek:
            if (now.difference(articleDate).inDays > 7) return false;
            break;
          case PublishDateFilter.custom:
            if (filters.customStartDate != null && 
                articleDate.isBefore(filters.customStartDate!)) {
              return false;
            }
            if (filters.customEndDate != null && 
                articleDate.isAfter(filters.customEndDate!)) {
              return false;
            }
            break;
          case PublishDateFilter.all:
            break;
        }
      }

      // Source filter
      if (filters.sources.isNotEmpty) {
        final articleSource = article.source?.toLowerCase() ?? '';
        final hasMatchingSource = filters.sources.any(
          (filterSource) => articleSource.contains(filterSource.toLowerCase()),
        );
        if (!hasMatchingSource) return false;
      }

      // News type filter
      if (filters.newsTypes.isNotEmpty) {
        // This would need to be added to NewsArticleModel
        // For now, we'll skip this filter
      }

      // Trending vs Latest (this would need additional logic based on views, shares, etc.)
      // For now, we'll skip this filter

      return true;
    }).toList();
  }

  /// Applies filters with debouncing for performance
  static void filterWithDebounce(
    List<NewsArticleModel> articles,
    FilterModel filters,
    Function(List<NewsArticleModel>) onFiltered,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      final filteredArticles = filterNews(articles, filters);
      onFiltered(filteredArticles);
    });
  }

  /// Sorts articles based on trending vs latest
  static List<NewsArticleModel> sortArticles(
    List<NewsArticleModel> articles,
    bool isTrending,
  ) {
    if (isTrending) {
      // Sort by views, shares, or other engagement metrics
      // For now, we'll sort by title length as a placeholder
      return List.from(articles)..sort((a, b) => 
        (b.title.length).compareTo(a.title.length));
    } else {
      // Sort by publish date (latest first)
      return List.from(articles)..sort((a, b) {
        final dateA = a.publishedAt ?? DateTime(1970);
        final dateB = b.publishedAt ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    }
  }

  /// Generates API query parameters for server-side filtering
  static Map<String, String> getApiQueryParams(FilterModel filters) {
    final params = <String, String>{};

    if (filters.categories.isNotEmpty) {
      params['category'] = filters.categories.join(',');
    }

    if (filters.languages.isNotEmpty) {
      params['language'] = filters.languages.join(',');
    }

    if (filters.regions.isNotEmpty) {
      params['country'] = filters.regions.join(',');
    }

    // Add date filtering
    if (filters.publishDate == PublishDateFilter.today) {
      final today = DateTime.now();
      params['from_date'] = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    } else if (filters.publishDate == PublishDateFilter.last24Hours) {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      params['from_date'] = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    } else if (filters.publishDate == PublishDateFilter.thisWeek) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      params['from_date'] = '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
    } else if (filters.publishDate == PublishDateFilter.custom) {
      if (filters.customStartDate != null) {
        final start = filters.customStartDate!;
        params['from_date'] = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      }
      if (filters.customEndDate != null) {
        final end = filters.customEndDate!;
        params['to_date'] = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      }
    }

    return params;
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
