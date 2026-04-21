/// Central place for all app-wide constants.
/// Change baseUrl here only — nothing else needs touching.
class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://192.168.192.133:8000/api';

  // API endpoints
  static const String categoriesEndpoint = '/categories/';
  static const String subcategoriesEndpoint = '/subcategories/';
  static const String videosEndpoint = '/videos/';
  static const String adsEndpoint = '/ads/';
  static const String bannersEndpoint = '/banners/';

  // Pagination
  static const int pageSize = 20;

  // UI
  static const double gridSpacing = 12.0;
  static const double cardRadius = 16.0;
  static const double screenPadding = 16.0;
}
