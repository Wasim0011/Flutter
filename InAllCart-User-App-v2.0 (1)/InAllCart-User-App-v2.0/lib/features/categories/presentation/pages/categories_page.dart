import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../../core/utils/bottom_nav_scroll_controller.dart';
import '../../../app_content/domain/entities/app_content.dart';
import '../../../app_content/presentation/bloc/app_content_bloc.dart';
import '../../../app_content/presentation/widgets/category_widget.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/widgets/global_search_bar.dart';



class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    BottomNavScrollController().attachToScrollController(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<CategoryBloc>()..add(LoadCategories()),
        ),
        BlocProvider(
          create: (_) => getIt<AppContentBloc>()..add(const LoadCategoryScreenContent()),
        ),
      ],
      child: Scaffold(
        appBar: const GlobalAppBar(
          title: 'Categories',
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            const GlobalSearchBar(
              showAiButton: false,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            ),
            Expanded(
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, categoryState) {
                  if (categoryState is CategoryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (categoryState is CategoryError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(categoryState.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<CategoryBloc>().add(LoadCategories()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (categoryState is CategoriesLoaded) {
                    if (categoryState.categories.isEmpty) {
                      return const Center(child: Text('No categories found'));
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<CategoryBloc>().add(LoadCategories());
                        context.read<AppContentBloc>().add(const LoadCategoryScreenContent(forceRefresh: true));
                      },
                      child: _buildCategoryList(context, categoryState.categories),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<Category> categories) {
    return BlocBuilder<AppContentBloc, AppContentState>(
      builder: (context, state) {
        if (state is AppContentLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AppContentError) {
          return Center(
            child: Text(
              'Failed to load categories',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        // Get category widgets from category screen content
        // The new endpoint only returns category screen content, no need to filter
        final categoryWidgets = <AppContent>[];
        if (state is AppContentLoaded) {
          categoryWidgets.addAll(state.contents);
        }

        // If no widgets to show, display empty state
        if (categoryWidgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 40, color: Colors.grey[200]),
                const SizedBox(height: 10),
                Text(
                  'No categories found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          addAutomaticKeepAlives: false,
          itemCount: categoryWidgets.length,
          itemBuilder: (context, index) {
            final widget = categoryWidgets[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: CategoryContentWidget(
                content: widget,
                onCategoryTap: (categoryId) {
                  final category = CategoryUtils.findCategoryById(categories, categoryId) ?? 
                      (categories.isNotEmpty 
                        ? categories.first 
                        : Category(
                            id: categoryId, 
                            name: 'Category', 
                            flags: const CategoryFlags(isActive: true, isFeatured: false),
                          ));
                  context.push('${Routes.category(categoryId.toString())}?name=${Uri.encodeComponent(category.name)}');
                },
                onViewAllTap: () {
                  // Optional: Navigate to all categories or do nothing
                },
              ),
            );
          },
        );
      },
    );
  }
}
