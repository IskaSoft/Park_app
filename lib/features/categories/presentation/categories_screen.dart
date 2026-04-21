// lib/features/categories/presentation/categories_screen.dart
// Replace entire file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_providers.dart';
import '../../../core/models/models.dart';
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
        title: const Text('Park'),
        actions: [
          // Saved videos button with count badge
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
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (page) {
          if (page.results.isEmpty) {
            return const EmptyStateWidget(
              message: 'No categories available.',
              icon: Icons.category_outlined,
            );
          }
          return _CategoryGrid(categories: page.results);
        },
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return MediaCard(
          title: cat.title,
          imageUrl: cat.image,
          badge: cat.hasSubcategories
              ? '${cat.subcategoryCount} topics'
              : '${cat.videoCount} videos',
          onTap: () => _navigate(context, cat),
        );
      },
    );
  }
}
