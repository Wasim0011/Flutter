import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/Notifications/NotificationScreen.dart';
import 'package:gossipcom/auth/auth_service.dart';
import 'package:gossipcom/news/news_service.dart';
import 'package:gossipcom/news/filter_model.dart';
import 'package:gossipcom/news/filter_service.dart';
import 'package:gossipcom/news/filter_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../news/news_model.dart';
import '../news/news_tile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  AuthService authService = AuthService();
  NewsService newsService = NewsService();
  late Future<List<NewsArticleModel>> newsFuture;

  List<Map<String, dynamic>> newsArticles = [];
  List<NewsArticleModel> filteredArticles = [];
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMoreData = true;
  bool isInitialLoading = true;
  final ScrollController scrollController = ScrollController();

  FilterModel currentFilters = const FilterModel();
  bool isFiltering = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _initializeData() async {
    await _loadNews();
  }

  void _applyFilters(FilterModel filters) {
    setState(() {
      currentFilters = filters;
      isFiltering = true;
    });

    FilterService.filterWithDebounce(
      newsArticles.map((article) => _convertToNewsArticle(article)).toList(),
      filters,
      (filtered) {
        if (mounted) {
          setState(() {
            filteredArticles = filtered;
            isFiltering = false;
          });
        }
      },
    );
  }

  Future<void> _loadNews({bool isRefresh = false}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      if (isRefresh) {
        newsArticles.clear();
        lastDocument = null;
        hasMoreData = true;
        isInitialLoading = true;
      }
    });

    try {
      final newArticles = await newsService.fetchNews(
        lastdoc: lastDocument,
        limit: 10,
      );

      List<Map<String, dynamic>> updatedArticles;
      DocumentSnapshot? newLastDocument = lastDocument;
      bool newHasMoreData = hasMoreData;

      if (newArticles.isNotEmpty) {
        updatedArticles =
            isRefresh ? newArticles : [...newsArticles, ...newArticles];
        newLastDocument = newArticles.last['doc'] as DocumentSnapshot?;

        if (newArticles.length < 10) {
          newHasMoreData = false;
        }
      } else {
        updatedArticles = isRefresh ? [] : newsArticles;
        newHasMoreData = false;
      }

      setState(() {
        newsArticles = updatedArticles;
        lastDocument = newLastDocument;
        hasMoreData = newHasMoreData;
        isLoading = false;
        isInitialLoading = false;
      });

      if (currentFilters.hasActiveFilters) {
        _applyFilters(currentFilters);
      } else {
        setState(() {
          filteredArticles = newsArticles
              .map((article) => _convertToNewsArticle(article))
              .toList();
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isInitialLoading = false;
      });
      debugPrint('Error loading News: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading news: $e')),
        );
      }
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      if (hasMoreData && !isLoading) {
        _loadNews();
      }
    }
  }

  NewsArticleModel _convertToNewsArticle(Map<String, dynamic> data) {
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is List) return value.join(', ');
      return value.toString();
    }

    return NewsArticleModel(
      articleId:
          safeString(data['article_id']), // Fixed: Added required parameter
      title: safeString(data['title']),
      description: safeString(data['description']),
      category: safeString(data['category']),
      link: safeString(data['link']),
      imageLink: safeString(data['image_url']),
      publishedAt: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      source: safeString(data['source_id']),
      language: safeString(data['language']),
      newsType: safeString(data['content_type']),
      views: data['views'] ?? 0,
      shares: data['shares'] ?? 0,
    );
  }

  List<NewsArticleModel> _getDisplayArticles() {
    return currentFilters.hasActiveFilters
        ? filteredArticles
        : newsArticles
            .map((article) => _convertToNewsArticle(article))
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final displayArticles = _getDisplayArticles();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      elevation: 10,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: screenHeight * 0.06,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            "Recent Update",
                            style: GoogleFonts.dmSerifText(
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => FilterWidget(
                          currentFilters: currentFilters,
                          onFiltersChanged: _applyFilters,
                          onClearAll: () {
                            setState(() {
                              currentFilters = const FilterModel();
                              filteredArticles = newsArticles
                                  .map((article) =>
                                      _convertToNewsArticle(article))
                                  .toList();
                            });
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentFilters.hasActiveFilters
                            ? const Color(0xFF1976D2)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.filter_list,
                        color: currentFilters.hasActiveFilters
                            ? Colors.white
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Image.asset(
                      "assets/notificationIcon.png",
                      height: 30,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isInitialLoading
                  ? Center(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Column(
                          children: List.generate(
                            5,
                            (index) => Padding(
                              padding: const EdgeInsets.all(22.0),
                              child: Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : displayArticles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                currentFilters.hasActiveFilters
                                    ? Icons.filter_alt_off
                                    : Icons.article_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentFilters.hasActiveFilters
                                    ? "No articles match your filters"
                                    : "No News Available",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (currentFilters.hasActiveFilters)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      currentFilters = const FilterModel();
                                      filteredArticles = newsArticles
                                          .map((article) =>
                                              _convertToNewsArticle(article))
                                          .toList();
                                    });
                                  },
                                  child: Text(
                                    'Clear Filters',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1976D2),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadNews(isRefresh: true),
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount:
                                displayArticles.length + (hasMoreData ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= displayArticles.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(22.0),
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final article = displayArticles[index];
                              final articleData = newsArticles.firstWhere(
                                (item) =>
                                    _convertToNewsArticle(item).title ==
                                    article.title,
                                orElse: () => {},
                              );

                              return VisibilityDetector(
                                key: Key(
                                  'newsFetch_${articleData['article_id']?.toString() ?? index.toString()}',
                                ),
                                onVisibilityChanged: (info) {
                                  if (info.visibleFraction > 0.7) {
                                    Future.delayed(
                                        const Duration(milliseconds: 800), () {
                                      if (mounted) {
                                        // Trigger analytics or tracking
                                      }
                                    });
                                  }
                                },
                                child: NewsTile(
                                  category: article.category,
                                  news: article.description,
                                  link: article.link,
                                  imageLink: article.imageLink,
                                  title: article.title,
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
