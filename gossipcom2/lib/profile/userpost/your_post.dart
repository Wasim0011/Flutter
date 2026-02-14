import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/thoughts/add_thought.dart';
import 'package:gossipcom/thoughts/thought_tile.dart';
import 'package:gossipcom/thoughts/thoughts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:developer';

class UserPosts extends StatefulWidget {
  const UserPosts({super.key});

  @override
  State<UserPosts> createState() => _UserPostsState();
}

class _UserPostsState extends State<UserPosts> {
  ThoughtsService thoughtsService = ThoughtsService();
  bool _isLoadingInitial = true;

  final Map<String, bool> _viewedPosts = {};
  List<Map<String, dynamic>> _thoughts = [];
  bool _isloadingMore = false;
  bool _hasData = true;
  final ScrollController _scrollController = ScrollController();

  Future<void> _fetchInitialUserPosts() async {
    setState(() {
      _isLoadingInitial = true;
    });
    try {
      log("DEBUG: Fetching initial user posts...");
      final initialThoughts = await thoughtsService.fetchUserPosts();
      log("DEBUG: Received ${initialThoughts.length} posts");
      log("DEBUG: Posts data: $initialThoughts");

      setState(() {
        _thoughts = initialThoughts;
        if (initialThoughts.isNotEmpty) {}
        _hasData = initialThoughts.length == 10;
        _isLoadingInitial = false;
      });
    } catch (e) {
      debugPrint('Error fetching initial user posts: $e');
      setState(() {
        _isLoadingInitial = false;
        _hasData = false;
      });
    }
  }

  Future<void> _fetchMoreUserPosts() async {
    setState(() {
      _isloadingMore = true;
    });

    try {
      // Note: You'll need to modify fetchUserPosts to support pagination
      // For now, this will just reload all posts
      final newThoughts = await thoughtsService.fetchUserPosts();

      setState(() {
        if (newThoughts.length > _thoughts.length) {
          _thoughts = newThoughts;
          if (newThoughts.isNotEmpty) {}
        }
        _hasData = false; // Disable further loading for now
        _isloadingMore = false;
      });
    } catch (e) {
      debugPrint('Error fetching more user posts: $e');
      setState(() {
        _isloadingMore = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadViewedPosts();
    _fetchInitialUserPosts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isloadingMore &&
          _hasData) {
        _fetchMoreUserPosts();
      }
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: screenHeight * 0.06,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              child: Row(
                children: [
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      height: 53,
                      width: screenWidth * 0.8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          "My Posts",
                          style: GoogleFonts.dmSerifText(
                              fontWeight: FontWeight.w400,
                              fontSize: 32,
                              color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.edit_calendar_sharp,
                    ),
                    iconSize: 30,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AddThought()));
                },
                child: Container(
                  height: screenHeight * 0.05,
                  width: screenWidth * 0.75,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Color(0x33736F6F)),
                  child: Center(
                      child: Text(
                    "Add Your Thought Or Ask Question",
                    style: GoogleFonts.dmSerifText(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.w400),
                  )),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Colors.grey,
                onRefresh: () async {
                  await _fetchInitialUserPosts(); // Refresh UI manually
                },
                child: _isLoadingInitial
                    ? ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                              padding: EdgeInsets.all(5),
                              child: Shimmer.fromColors(
                                  enabled: true,
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: SingleChildScrollView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: List.generate(
                                            5,
                                            (index) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                      horizontal: 16.0),
                                              child: Container(
                                                height: 100,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          )))));
                        })
                    : _thoughts.isEmpty
                        ? Center(
                            child: Text(
                              "No Posts Found",
                              style: GoogleFonts.dmSerifText(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                _thoughts.length + (_isloadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _thoughts.length) {
                                // Loading indicator at the bottom
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              var thought = _thoughts[index];
                              String postId =
                                  thought['id'] ?? thought['postId'] ?? '';

                              // Debug print to check data structure
                              log("DEBUG: Thought data: $thought");
                              log("DEBUG: Post ID: $postId");

                              return VisibilityDetector(
                                key: Key('user-post-$postId'),
                                onVisibilityChanged: (VisibilityInfo info) {
                                  if (info.visibleFraction > 0.7) {
                                    Future.delayed(
                                        const Duration(milliseconds: 800), () {
                                      if (mounted) {
                                        _incrementview(postId);
                                      }
                                    });
                                  }
                                },
                                child: Column(
                                  children: [
                                    SingleChildScrollView(
                                      child: ThoughtTile(
                                        userName: thought["username"] ??
                                            thought["userName"] ??
                                            "Anonymous",
                                        thought: thought["thought"] ?? "",
                                        thoughtid: postId,
                                        UserId: thought['userId'] ?? "",
                                        imageUrls:
                                            (thought['imagelink'] is List)
                                                ? (thought['imagelink'] as List)
                                                : null,
                                        views: thought['views'] ?? 0,
                                      ),
                                    ),
                                  ],
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
