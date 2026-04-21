// lib/features/videos/providers/video_providers.dart
// Replace entire file.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../data/video_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => VideoRepository(ref.read(apiClientProvider)),
);

// ── Filter ────────────────────────────────────────────────────────────────────

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

final videosProvider =
    FutureProvider.family<PaginatedResponse<Video>, VideoFilter>(
  (ref, filter) => ref.read(videoRepositoryProvider).fetchVideos(
        categoryId: filter.categoryId,
        subcategoryId: filter.subcategoryId,
      ),
);
