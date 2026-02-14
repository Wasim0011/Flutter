import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/thoughts/add_gossip_thought.dart';
import 'package:gossipcom/thoughts/add_thought.dart';
import 'package:gossipcom/thoughts/gossip_thought_tile.dart';
import 'package:gossipcom/thoughts/thought_tile.dart';
import 'package:gossipcom/thoughts/thoughts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category>
    with SingleTickerProviderStateMixin {
  ThoughtsService thoughtsService = ThoughtsService();

  final Map<String, bool> _viewedPosts = {};
  List<Map<String, dynamic>> _thoughts = [];
  bool _isloadingMore = false;
  bool _hasData = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  Future<void> _fetchInitialThoughts() async {
    setState(() {});
    final initialThoughts = await thoughtsService.fetchThoughts(limit: 10);
    setState(() {
      _thoughts = initialThoughts;
      if (initialThoughts.isNotEmpty) {
        _lastDocument = initialThoughts.last['doc'];
      }
      _hasData = initialThoughts.length == 10;
    });
  }

  Future<void> _fetchMoreThoughts() async {
    setState(() {
      _isloadingMore = true;
    });

    final newThoughts = await thoughtsService.fetchThoughts(
      lastDoc: _lastDocument,
      limit: 10,
    );

    setState(() {
      _thoughts.addAll(newThoughts);
      if (newThoughts.isNotEmpty) {
        _lastDocument = newThoughts.last['doc'];
      }
      _hasData = newThoughts.length == 10;
      _isloadingMore = false;
    });
  }

  Future<void> _loadViewedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedPosts = prefs.getStringList('viewed_posts') ?? [];

      if (mounted) {
        setState(() {
          for (var postId in viewedPosts) {
            _viewedPosts[postId] = true;
          }
        });
      }
      log("Loaded ${viewedPosts.length} previously viewed posts");
    } catch (e) {
      log("Error loading viewed posts: $e");
    }
  }

  Future<bool> _checkIfViewed(String postId) async {
    if (_viewedPosts.containsKey(postId)) {
      return _viewedPosts[postId]!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedPosts = prefs.getStringList('viewed_posts') ?? [];
      final hasViewed = viewedPosts.contains(postId);
      _viewedPosts[postId] = hasViewed;
      return hasViewed;
    } catch (e) {
      log("Error checking if post viewed: $e");
      return false;
    }
  }

  Future<void> _incrementview(String postId) async {
    try {
      bool alreadyViewed = await _checkIfViewed(postId);
      if (!alreadyViewed) {
        debugPrint("increment view for posts:$postId");
        final postRef =
            FirebaseFirestore.instance.collection('Posts').doc(postId);
        await postRef.update({
          'views': FieldValue.increment(1),
        });
        final prefs = await SharedPreferences.getInstance();
        final viewedPosts = prefs.getStringList('viewed_posts') ?? [];
        viewedPosts.add(postId);
        await prefs.setStringList('viewed_posts', viewedPosts);
        _viewedPosts[postId] = true;
      }
      log("View incremented successfully for: $postId");
    } catch (e) {
      log("Error while updating view: $e");
    }
  }

  Future<void> _incrementviewgossip(String postId) async {
    try {
      bool alreadyViewed = await _checkIfViewed(postId);
      if (!alreadyViewed) {
        debugPrint("increment view for posts:$postId");
        final postRef =
            FirebaseFirestore.instance.collection('GossipPosts').doc(postId);
        await postRef.update({
          'views': FieldValue.increment(1),
        });
        final prefs = await SharedPreferences.getInstance();
        final viewedPosts = prefs.getStringList('viewed_posts') ?? [];
        viewedPosts.add(postId);
        await prefs.setStringList('viewed_posts', viewedPosts);
        _viewedPosts[postId] = true;
      }
      log("View incremented successfully for: $postId");
    } catch (e) {
      log("Error while updating view: $e");
    }
  }

  // gossipRequest
  List<Map<String, dynamic>> _gossipThought = [];
  bool _isLoadingMoreGossip = false;
  bool _hasGossipData = true;
  DocumentSnapshot? _gossipLastDocument;
  final _gossipThoughtScrollController = ScrollController();

  late TabController _tabController;

  Future<void> _gossipInitialThought() async {
    setState(() {});
    final initialGossipThought =
        await thoughtsService.fetchGossipThoughts(limit: 10);
    setState(() {
      _gossipThought = initialGossipThought;
      if (initialGossipThought.isNotEmpty) {
        _gossipLastDocument = initialGossipThought.last['doc'];
      }
      _hasGossipData = initialGossipThought.length == 10;
    });
  }


  Future<void> _gossipLoadMoreThought() async {
    setState(() {
      _isLoadingMoreGossip = true;
    });
    final loadGossipThought = await thoughtsService.fetchGossipThoughts(
        lastDoc: _gossipLastDocument, limit: 10);
    setState(() {
      _gossipThought.addAll(loadGossipThought);
      if (loadGossipThought.isNotEmpty) {
        _gossipLastDocument = loadGossipThought.last['doc'];
      }
      _hasGossipData = loadGossipThought.length == 10;
      _isLoadingMoreGossip = false;
    });
  }

  bool _handleScrollNotification(
      ScrollNotification notification, bool isGossip) {
    if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 300) {
        if (isGossip && !_isLoadingMoreGossip && _hasGossipData) {
          _gossipLoadMoreThought();
        } else if (!isGossip && !_isloadingMore && _hasData) {
          _fetchMoreThoughts();
        }
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadViewedPosts();
    _fetchInitialThoughts();
    _gossipInitialThought();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isloadingMore &&
          _hasData) {
        _fetchMoreThoughts();
      }
    });
    _gossipThoughtScrollController.addListener(() {
      if (_gossipThoughtScrollController.position.pixels >=
              _gossipThoughtScrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMoreGossip &&
          _hasGossipData) {
        _gossipLoadMoreThought();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _gossipThoughtScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                snap: true,
                floating: true,
                pinned: false,
                expandedHeight: screenHeight * 0.18,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Column(
                      // make the column size fit its children and avoid forcing excess height
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // reduced top spacing (was too large on some screens)
                        SizedBox(
                          height: screenHeight * 0.02,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(13),
                                  child: Container(
                                    height: 50,
                                    width: screenWidth * 0.8,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.tertiary,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Thoughts & Q n A",
                                        style: GoogleFonts.dmSerifText(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 32,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // use a fixed double value to prevent fractional sub-pixel issues
                        SizedBox(
                          height: 40.0,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: Colors.blue,
                              unselectedLabelColor: Colors.brown,
                              tabs: [
                                Tab(
                                  child: Text(
                                    "Post",
                                    style: GoogleFonts.dmSerifText(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFFA0A0A0)
                                          : Colors.grey,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Text(
                                    'Gossip Post',
                                    style: GoogleFonts.dmSerifText(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFFA0A0A0)
                                          : Colors.grey,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                NotificationListener<ScrollNotification>(
                    onNotification: (notification) =>
                        _handleScrollNotification(notification, false),
                    child: normalPost()),
                NotificationListener<ScrollNotification>(
                    onNotification: (notification) =>
                        _handleScrollNotification(notification, true),
                    child: gosipPost()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget normalPost() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchInitialThoughts();
      },
      child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Container(
                  // keep a minimum height but allow the container to grow if content needs more space
                  constraints: BoxConstraints(minHeight: screenHeight * 0.11),
                  width: screenWidth * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0x33CCCCCC)
                        : const Color(0x33736F6F),
                  ),
                  // Use a Column that can expand naturally inside the minHeight constraint
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                        child: Center(
                          child: Text(
                            " Add your thoughts, ask questions or share any topic you’d like to talk about. ",
                            style: GoogleFonts.dmSerifText(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFA0A0A0)
                                  : Colors.grey,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.01, vertical: 6),
                        child: Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddThought(),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.add,
                                  size: 18.sp,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_thoughts.isEmpty)
              if (_hasData)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(5),
                        child: Shimmer.fromColors(
                          enabled: true,
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Column(
                            children: List.generate(
                              1,
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 16.0),
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
                      );
                    },
                    childCount: 5,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        "No Thoughts Found",
                        style: GoogleFonts.dmSerifText(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var thought = _thoughts[index];
                    String postId = thought['postId'] ?? '';

                    return VisibilityDetector(
                      key: Key('post-$postId'),
                      onVisibilityChanged: (VisibilityInfo info) {
                        if (info.visibleFraction > 0.7) {
                          Future.delayed(const Duration(milliseconds: 800),
                              () {
                            if (mounted) {
                              _incrementview(postId);
                            }
                          });
                        }
                      },
                      child: Column(
                        children: [
                          ThoughtTile(
                            userName: thought["username"] ?? "Anonymous",
                            thought: thought["thought"] ?? "",
                            thoughtid: thought['postId'] ?? "",
                            UserId: thought['userId'] ?? "",
                            imageUrls: thought['imagelink'] ?? "https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png",
                            views: thought['views'] ?? "",
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _thoughts.length,
                ),
              ),

            // larger bottom padding to ensure no clipping on shorter viewports / devices
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ]),
    );
  }

  Widget gosipPost() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return RefreshIndicator(
      onRefresh: () async {
        await _gossipInitialThought();
      },
      child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Container(
              constraints: BoxConstraints(minHeight: screenHeight * 0.11),
              width: screenWidth * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0x33CCCCCC)
                    : const Color(0x33736F6F),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                    child: Center(
                      child: Text(
                        " Add your thoughts, ask questions or share any topic you’d like to talk about. ",
                        style: GoogleFonts.dmSerifText(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFA0A0A0)
                              : Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.01, vertical: 6),
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddGossipThought(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_gossipThought.isEmpty)
          if (_hasGossipData)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                      padding: const EdgeInsets.all(5),
                      child: Shimmer.fromColors(
                          enabled: true,
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Column(
                            children: List.generate(
                              1,
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 16.0),
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
                          )));
                },
                childCount: 5,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    "No Thoughts Found",
                    style: GoogleFonts.dmSerifText(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                var gossipthought = _gossipThought[index];
                String postId = gossipthought['postId'] ?? '';

                return VisibilityDetector(
                  key: Key('post-$postId'),
                  onVisibilityChanged: (VisibilityInfo info) {
                    if (info.visibleFraction > 0.7) {
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted) {
                          _incrementviewgossip(postId);
                        }
                      });
                    }
                  },
                  child: Column(
                    children: [
                      Gossipthoughttile(
                        userName: gossipthought["username"] ?? "Anonymous",
                        thought: gossipthought["thought"] ?? "",
                        thoughtid: gossipthought['postId'] ?? "",
                        userId: gossipthought['userId'] ?? "",
                        imageUrls: gossipthought['imagelink'] ?? "https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png",
                        views: gossipthought['views'] ?? "",
                        groupId: gossipthought['groupId'] ?? "",
                      ),
                    ],
                  ),
                );
              },
              childCount: _gossipThought.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ]),
    );
  }
}
