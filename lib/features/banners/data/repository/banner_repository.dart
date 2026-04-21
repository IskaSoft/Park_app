// lib/features/banners/data/banner_repository.dart
// NEW FILE

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../models/banner_model.dart';

class BannerRepository {
  const BannerRepository(this._client);
  final ApiClient _client;

  Future<List<BannerModel>> fetchBanners() async {
    final data = await _client.get(AppConstants.bannersEndpoint);
    // DRF returns paginated: {results: [...]} or plain list
    final list = data['results'] ?? data['data'] ?? [];
    return (list as List)
        .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
