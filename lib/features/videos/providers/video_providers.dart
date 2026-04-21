import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/models/paginated_response.dart';
import '../../categories/providers/category_providers.dart';
import '../data/video_repository.dart';

// ── Filter params ─────────────────────────────────────────────────────────────

class VideoFilter {
  const VideoFilter({this.categoryId, this.subcategoryId});
  final int? categoryId;
  final int? subcategoryId;

  @override
  bool operator ==(Object other) =>
      other is VideoFilter &&
      other.categoryId == categoryId &&
      other.subcategoryId == subcategoryId;

  @override
  int get hashCode => Object.hash(categoryId, subcategoryId);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => VideoRepository(ref.read(apiClientProvider)),
);

final videosProvider =
    FutureProvider.family<PaginatedResponse<Video>, VideoFilter>(
  (ref, filter) async {
    return ref.read(videoRepositoryProvider).fetchVideos(
          categoryId: filter.categoryId,
          subcategoryId: filter.subcategoryId,
        );
  },
);
