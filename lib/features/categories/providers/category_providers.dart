import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';
import '../data/category_repository.dart';

// ── Infrastructure providers ──────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.read(apiClientProvider)),
);

// ── Data providers ────────────────────────────────────────────────────────────

final categoriesProvider =
    FutureProvider<PaginatedResponse<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).fetchCategories();
});

final subcategoriesProvider =
    FutureProvider.family<PaginatedResponse<Subcategory>, int>(
  (ref, categoryId) async {
    return ref.read(categoryRepositoryProvider).fetchSubcategories(categoryId);
  },
);
