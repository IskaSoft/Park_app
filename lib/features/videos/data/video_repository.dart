import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';

class VideoRepository {
  const VideoRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResponse<Video>> fetchVideos({
    int? categoryId,
    int? subcategoryId,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (categoryId != null) params['category'] = categoryId.toString();
    if (subcategoryId != null) params['subcategory'] = subcategoryId.toString();

    final data = await _client.get(AppConstants.videosEndpoint, params: params);
    return PaginatedResponse.fromJson(data, Video.fromJson);
  }

  Future<Video> fetchVideo(int id) async {
    final data = await _client.get('${AppConstants.videosEndpoint}$id/');
    return Video.fromJson(data);
  }
}
