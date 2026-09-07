import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/search_bloc.dart';

class SearchPage extends StatelessWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBloc(getIt(), getIt())
        ..add(initialQuery != null && initialQuery!.isNotEmpty
            ? SearchQueryChanged(initialQuery!)
            : LoadSearchHistory()),
      child: const SearchView(),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    
    // Access the initial query from the Bloc if needed, but for now we just start empty/focused
    // Or if `initialQuery` was passed, we might want to set text.
    // However, BlocProvider above handles the event. We should also sync controller text.
    context.read<SearchBloc>();
    // If we wanted to preserve initial text:
    // _controller.text = widget.initialQuery ?? ''; 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(BuildContext context, String query) {
    if (query.trim().isEmpty) return;
    
    // Save to search history
    context.read<SearchBloc>().add(AddToHistory(query));
    
    // Navigate to Products page with search query
    context.pushNamed(
      RouteNames.products,
      queryParameters: {'q': query},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search for products...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                        onPressed: () {
                          _controller.clear();
                          context.read<SearchBloc>().add(SearchReset());
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                context.read<SearchBloc>().add(SearchQueryChanged(value));
              },
              onSubmitted: (value) => _onSearchSubmitted(context, value),
            ),
          ),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(
              child: SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(strokeWidth: 2)
              )
            );
          }

          if (state is SearchError) {
             return Center(
               child: Text(
                 state.message, 
                 style: const TextStyle(color: Colors.red)
               )
             );
          }

          if (state is SearchLoaded) {
            if (state.products.isEmpty && state.categories.isEmpty) {
              return _buildEmptyState();
            }
            return _buildSuggestionsList(context, state);
          }

          if (state is SearchHistoryLoaded) {
            return _buildHistoryList(context, state.history);
          }

          return _buildInitialState();
        },
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<String> history) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<SearchBloc>().add(ClearHistory());
                },
                child: const Text('Clear all', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
        ),
        ...history.map((query) => ListTile(
          leading: const Icon(Icons.history, color: Colors.grey, size: 20),
          title: Text(query, style: const TextStyle(fontSize: 15)),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () {
              context.read<SearchBloc>().add(RemoveFromHistory(query));
            },
          ),
          onTap: () {
            _controller.text = query;
            _onSearchSubmitted(context, query);
          },
        )),
      ],
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'Type to search products',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'No matching products found',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context, SearchLoaded state) {
    return CustomScrollView(
      slivers: [
        // Categories Section
        if (state.categories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'CATEGORIES', 
                style: TextStyle(
                  color: Colors.grey[600], 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                )
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = state.categories[index];
                return ListTile(
                  leading: const Icon(Icons.category_outlined, size: 20, color: Colors.grey),
                  title: Text(category['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                     final id = category['id'].toString();
                     final name = category['name'];
                     
                     // Save current query to history before navigating
                     if (_controller.text.isNotEmpty) {
                       context.read<SearchBloc>().add(AddToHistory(_controller.text));
                     }
                     
                     context.pushNamed(
                       RouteNames.categoryProducts,
                       pathParameters: {'id': id},
                       queryParameters: {'name': name},
                     );
                  },
                );
              },
              childCount: state.categories.length,
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),
        ],

        // Products Section
        if (state.products.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'PRODUCTS', 
                style: TextStyle(
                  color: Colors.grey[600], 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                )
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = state.products[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedImage(
                      imageUrl: AppConstants.getFullMediaUrl(product['image'] ?? product['image_url'] ?? product['thumbnail']),
                      fit: BoxFit.cover,
                      errorWidget: const Icon(Icons.broken_image, size: 16, color: Colors.grey),
                    ),
                  ),
                  title: Text(product['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    product['category_name'] ?? '', 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
                  onTap: () {
                    // Save current query to history before navigating
                    if (_controller.text.isNotEmpty) {
                      context.read<SearchBloc>().add(AddToHistory(_controller.text));
                    }

                    context.pushNamed(
                      RouteNames.productDetails,
                      pathParameters: {'id': product['id'].toString()},
                    );
                  },
                );
              },
              childCount: state.products.length,
            ),
          ),
        ],

        // Add bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}
