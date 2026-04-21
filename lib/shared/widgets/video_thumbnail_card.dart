// lib/shared/widgets/video_thumbnail_card.dart
// Replace entire file.

import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/utils/time_utils.dart';

class VideoThumbnailCard extends StatelessWidget {
  const VideoThumbnailCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  final Video video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0F3460),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Thumbnail ──────────────────────────────────────────────────
              _ThumbnailImage(url: video.thumbnailUrl),

              // ── Gradient ───────────────────────────────────────────────────
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1.0],
                    colors: [Colors.transparent, Color(0xEE000000)],
                  ),
                ),
              ),

              // ── Views badge (top-right) ────────────────────────────────────
              Positioned(
                top: 8,
                right: 8,
                child: _ViewsBadge(viewsDisplay: video.viewsDisplay),
              ),

              // ── Play icon ──────────────────────────────────────────────────
              const Center(child: _PlayIcon()),

              // ── Title + time (bottom) ──────────────────────────────────────
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      TimeUtils.timeAgo(video.createdAt),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Views badge ───────────────────────────────────────────────────────────────

class _ViewsBadge extends StatelessWidget {
  const _ViewsBadge({required this.viewsDisplay});
  final String viewsDisplay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_rounded, color: Colors.white70, size: 11),
          const SizedBox(width: 3),
          Text(
            viewsDisplay,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Thumbnail image ───────────────────────────────────────────────────────────

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(color: const Color(0xFF1E2A4A));
      },
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF1E2A4A),
        child: const Icon(Icons.play_circle_outline,
            color: Colors.white24, size: 44),
      );
}

// ── Play icon ─────────────────────────────────────────────────────────────────

class _PlayIcon extends StatelessWidget {
  const _PlayIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}
