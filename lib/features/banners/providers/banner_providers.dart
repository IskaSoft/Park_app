// lib/features/banners/providers/banner_providers.dart
// NEW FILE

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:park_app/features/banners/data/repository/banner_repository.dart';
import '../../categories/providers/category_providers.dart';
import '../models/banner_model.dart';

final bannerRepositoryProvider = Provider<BannerRepository>(
  (ref) => BannerRepository(ref.read(apiClientProvider)),
);

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  return ref.read(bannerRepositoryProvider).fetchBanners();
});
