import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../data/datasources/static_pages_remote_datasource.dart';
import '../../domain/entities/static_page.dart';
import '../cubit/static_pages_cubit.dart';
import 'static_page_detail_page.dart';

class GeneralInfoPage extends StatelessWidget {
  const GeneralInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StaticPagesCubit(
        StaticPagesRemoteDataSourceImpl(getIt<ApiClient>()),
      )..load(),
      child: const _GeneralInfoView(),
    );
  }
}

class _GeneralInfoView extends StatelessWidget {
  const _GeneralInfoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const GlobalAppBar(title: 'General Info'),
      body: BlocBuilder<StaticPagesCubit, StaticPagesState>(
        builder: (context, state) {
          if (state is StaticPagesLoading || state is StaticPagesInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StaticPagesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load pages',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        context.read<StaticPagesCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is StaticPagesLoaded) {
            if (state.pages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No pages available',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            return _PagesList(pages: state.pages);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PagesList extends StatelessWidget {
  final List<StaticPage> pages;

  const _PagesList({required this.pages});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: pages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final page = pages[index];
        return _PageTile(page: page);
      },
    );
  }
}

class _PageTile extends StatelessWidget {
  final StaticPage page;

  const _PageTile({required this.page});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StaticPageDetailPage(page: page),
        ),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconFor(page.icon),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                page.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 22, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String? icon) {
    switch (icon) {
      case 'privacy':
      case 'privacy_policy':
        return Icons.privacy_tip_outlined;
      case 'terms':
      case 'terms_conditions':
        return Icons.gavel_outlined;
      case 'refund':
      case 'refund_policy':
        return Icons.assignment_return_outlined;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'about':
        return Icons.info_outline;
      case 'contact':
        return Icons.contact_support_outlined;
      case 'faq':
        return Icons.help_outline;
      default:
        return Icons.article_outlined;
    }
  }
}
