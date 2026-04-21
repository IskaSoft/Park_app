// lib/shared/widgets/video_thumbnail_card.dart
// REPLACE entire file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/utils/time_utils.dart';
import '../../features/saved/saved_videos_service.dart';

/// TikTok-explore-style video card.
/// Now a ConsumerWidget so it can read saved state directly from Riverpod.
/// Each card only rebuilds when ITS OWN saved state changes (select filter).
class VideoThumbnailCard extends ConsumerWidget {
  const VideoThumbnailCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  final Video video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fine-grained selector: only rebuilds when this video's saved state changes
    final isSaved = ref.watch(
      savedVideosProvider.select((list) => list.any((v) => v.id == video.id)),
    );

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
              // Thumbnail
              _ThumbnailImage(url: video.thumbnailUrl),

              // Gradient overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 1.0],
                    colors: [Colors.transparent, Color(0xEE000000)],
                  ),
                ),
              ),

              // Top row: bookmark icon (left) + views badge (right)
              Positioned(
                top: 6,
                left: 6,
                right: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GridBookmarkButton(video: video, isSaved: isSaved),
                    _ViewsBadge(viewsDisplay: video.viewsDisplay),
                  ],
                ),
              ),

              // Centre play icon
              const Center(child: _PlayIcon()),

              // Bottom: title + time
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

// ─────────────────────────────────────────────────────────────────────────────
// Grid bookmark button
// Tapping toggles save without opening the video player.
// Has a pop/scale animation on tap.
// ─────────────────────────────────────────────────────────────────────────────

class _GridBookmarkButton extends ConsumerStatefulWidget {
  const _GridBookmarkButton({required this.video, required this.isSaved});
  final Video video;
  final bool isSaved;

  @override
  ConsumerState<_GridBookmarkButton> createState() =>
      _GridBookmarkButtonState();
}

class _GridBookmarkButtonState extends ConsumerState<_GridBookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    ref.read(savedVideosProvider.notifier).toggle(widget.video);
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              widget.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              key: ValueKey(widget.isSaved),
              color: widget.isSaved ? Colors.amber : Colors.white60,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

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
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : Container(color: const Color(0xFF1E2A4A)),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF1E2A4A),
        child: const Icon(Icons.play_circle_outline,
            color: Colors.white24, size: 44),
      );
}

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
      child:
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
    );
  }
}
