import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_providers.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../videos/presentation/video_grid_screen.dart';

class SubcategoryScreen extends ConsumerWidget {
  const SubcategoryScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  final int categoryId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subcategoriesProvider(categoryId));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: async.when(
        loading: () => const ShimmerGrid(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(subcategoriesProvider(categoryId)),
        ),
        data: (page) {
          if (page.results.isEmpty) {
            return const EmptyStateWidget(
              message: 'No subcategories found.',
              icon: Icons.folder_open_outlined,
            );
          }
          return _SubcategoryGrid(subcategories: page.results);
        },
      ),
    );
  }
}

class _SubcategoryGrid extends StatelessWidget {
  const _SubcategoryGrid({required this.subcategories});
  final List<Subcategory> subcategories;

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
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final sub = subcategories[index];
        return MediaCard(
          title: sub.title,
          imageUrl: sub.image,
          badge: sub.videoCount > 0 ? '${sub.videoCount} videos' : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoGridScreen(
                title: sub.title,
                subcategoryId: sub.id,
              ),
            ),
          ),
        );
      },
    );
  }
}
