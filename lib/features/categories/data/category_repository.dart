import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_client.dart';

class CategoryRepository {
  const CategoryRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResponse<Category>> fetchCategories({int page = 1}) async {
    final data = await _client.get(
      AppConstants.categoriesEndpoint,
      params: {'page': page.toString()},
    );
    return PaginatedResponse.fromJson(data, Category.fromJson);
  }

  Future<Category> fetchCategory(int id) async {
    final data = await _client.get('${AppConstants.categoriesEndpoint}$id/');
    return Category.fromJson(data);
  }

  Future<PaginatedResponse<Subcategory>> fetchSubcategories(
      int categoryId) async {
    final data = await _client.get(
      '${AppConstants.categoriesEndpoint}$categoryId/subcategories/',
    );
    return PaginatedResponse.fromJson(data, Subcategory.fromJson);
  }
}
