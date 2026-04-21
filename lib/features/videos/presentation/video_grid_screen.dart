import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_providers.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/video_thumbnail_card.dart';
import 'video_player_screen.dart';

class VideoGridScreen extends ConsumerWidget {
  const VideoGridScreen({
    super.key,
    required this.title,
    this.categoryId,
    this.subcategoryId,
  });

  final String title;
  final int? categoryId;
  final int? subcategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = VideoFilter(
      categoryId: categoryId,
      subcategoryId: subcategoryId,
    );
    final async = ref.watch(videosProvider(filter));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: async.when(
        loading: () => const ShimmerGrid(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(videosProvider(filter)),
        ),
        data: (page) {
          if (page.results.isEmpty) {
            return const EmptyStateWidget(
              message: 'No videos available.',
              icon: Icons.video_library_outlined,
            );
          }
          return _VideoGrid(videos: page.results);
        },
      ),
    );
  }
}

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.videos});
  final List<Video> videos;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoThumbnailCard(
          video: videos[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                videos: videos,
                initialIndex: index,
              ),
            ),
          ),
        );
      },
    );
  }
}
