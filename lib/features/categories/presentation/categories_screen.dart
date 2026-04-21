// lib/features/categories/presentation/categories_screen.dart
// REPLACE entire file.
//
// Added: proper error handling that shows NoInternetScreen
// instead of blank white screen when server is unreachable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:park_app/features/banners/presentation/banner_carousel.dart';
import '../providers/category_providers.dart';
import '../../../core/models/models.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/presentation/no_internet_screen.dart';
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../videos/presentation/video_grid_screen.dart';
import '../../saved/presentation/saved_videos_screen.dart';
import '../../saved/saved_videos_service.dart';
import 'subcategory_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);
    final savedCount = ref.watch(savedVideosProvider).length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo2.png', width: 36, height: 36),
            const SizedBox(width: 8),
            const Text('Seýil-Et!'),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.bookmark_rounded),
                tooltip: 'Saklanan wideolar',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavedVideosScreen(),
                  ),
                ),
              ),
              if (savedCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE94560),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        savedCount > 99 ? '99+' : savedCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: async.when(
        loading: () => const ShimmerGrid(),

        // ── Error handling — no blank white screen ─────────────────────────
        error: (error, _) {
          // Network / server error → show dedicated no-internet screen
          final isNetworkError =
              error is NetworkException || error is ServerException;

          if (isNetworkError) {
            return NoInternetScreen(
              onRetry: () => ref.invalidate(categoriesProvider),
            );
          }

          // Other errors → show inline error widget with retry
          return ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(categoriesProvider),
          );
        },

        data: (page) {
          if (page.results.isEmpty) {
            return const EmptyStateWidget(
              message: 'Kategoriýa ýok.',
              icon: Icons.category_outlined,
            );
          }
          return _CategoriesBody(categories: page.results);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading state — shimmer carousel + shimmer grid
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 16, bottom: 12),
            // BannerCarousel özünde shimmer görkezýär
            child: BannerCarousel(),
          ),
        ),
        SliverFillRemaining(child: ShimmerGrid()),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories body — carousel + grid
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesBody extends StatelessWidget {
  const _CategoriesBody({required this.categories});
  final List<Category> categories;

  void _navigate(BuildContext context, Category category) {
    if (category.hasSubcategories) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubcategoryScreen(
            categoryId: category.id,
            title: category.title,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoGridScreen(
            title: category.title,
            categoryId: category.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Banner carousel — ýokardan ──────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 16, bottom: 12),
            child: BannerCarousel(),
          ),
        ),

        // ── Kategoriýa grid ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = categories[index];
                return MediaCard(
                  title: cat.title,
                  imageUrl: cat.image,
                  badge: cat.hasSubcategories
                      ? '${cat.subcategoryCount} bölüm'
                      : '${cat.videoCount} wideo',
                  onTap: () => _navigate(context, cat),
                );
              },
              childCount: categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }
}
