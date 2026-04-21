// lib/core/models/models.dart
// Replace the entire file with this content.

class Category {
  const Category({
    required this.id,
    required this.title,
    required this.image,
    required this.subcategoryCount,
    required this.videoCount,
  });

  final int id;
  final String title;
  final String image;
  final int subcategoryCount;
  final int videoCount;

  bool get hasSubcategories => subcategoryCount > 0;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        title: json['title'] as String,
        image: json['image'] as String? ?? '',
        subcategoryCount: json['subcategory_count'] as int? ?? 0,
        videoCount: json['video_count'] as int? ?? 0,
      );
}

class Subcategory {
  const Subcategory({
    required this.id,
    required this.title,
    required this.image,
    this.videoCount = 0,
  });

  final int id;
  final String title;
  final String image;
  final int videoCount;

  factory Subcategory.fromJson(Map<String, dynamic> json) => Subcategory(
        id: json['id'] as int,
        title: json['title'] as String,
        image: json['image'] as String? ?? '',
        videoCount: json['video_count'] as int? ?? 0,
      );
}

class Video {
  const Video({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.createdAt,
    this.thumbnailUrl,
    this.description = '',
    this.views = 0,
    this.viewsDisplay = '0',
  });

  final int id;
  final String title;
  final String fileUrl;
  final String? thumbnailUrl;
  final String description;
  final DateTime createdAt;
  final int views;
  final String viewsDisplay; // "1.2K", "3.4M" etc.

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'] as int,
        title: json['title'] as String,
        fileUrl: json['file'] as String? ?? '',
        thumbnailUrl: json['thumbnail'] as String?,
        description: json['description'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        views: json['views'] as int? ?? 0,
        viewsDisplay: json['views_display'] as String? ?? '0',
      );

  /// Used for local storage (saved videos).
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'file': fileUrl,
        'thumbnail': thumbnailUrl,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'views': views,
        'views_display': viewsDisplay,
      };
}
