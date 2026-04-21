// lib/features/banners/models/banner_model.dart
// NEW FILE

class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  final int id;
  final String title;
  final String description;
  final String imageUrl;

  /// Banner image ýa-da wideo faýly — ikisem şol URL-den gelýär
  bool get isVideo {
    final lower = imageUrl.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi');
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['image'] as String? ?? '',
      );
}
