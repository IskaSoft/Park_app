// lib/features/videos/presentation/video_player_screen.dart
// Replace entire file.
//
// Fixes & features:
//   ✅ Play/Pause toggle — reliable, icon state always correct
//   ✅ Video resets to 0:00 on every open / page change
//   ✅ Double-tap left  → seek -10s
//   ✅ Double-tap right → seek +10s
//   ✅ View count incremented once per video via API
//   ✅ Save button in overlay
//   ✅ Memory management — dispose far-away controllers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/time_utils.dart';
import '../../../shared/widgets/save_button.dart';
import '../data/video_repository.dart';
import '../providers/video_providers.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  final List<Video> videos;
  final int initialIndex;

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late final PageController _pageController;
  final Map<int, VideoPlayerController> _controllers = {};

  int _currentIndex = 0;
  bool _showOverlay = true;

  // Tracks which videos have already had their view counted this session
  final Set<int> _viewedIds = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initPage(_currentIndex);
  }

  // ── Controller lifecycle ───────────────────────────────────────────────────

  Future<void> _initPage(int index) async {
    if (index < 0 || index >= widget.videos.length) return;

    // Preload current + next
    for (final i in [index, index + 1]) {
      if (i < 0 || i >= widget.videos.length) continue;
      if (_controllers.containsKey(i)) continue;
      await _createController(i);
    }

    // Play current, reset position to 0:00 (BUG FIX)
    final ctrl = _controllers[index];
    if (ctrl != null && ctrl.value.isInitialized) {
      await ctrl.seekTo(Duration.zero); // ← always reset position
      await ctrl.play();
      if (mounted) setState(() {});
    }

    _incrementViewCount(index);
    _disposeDistantControllers(index);
  }

  Future<void> _createController(int index) async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.videos[index].fileUrl),
    );
    _controllers[index] = ctrl;
    await ctrl.initialize();
    ctrl.setLooping(true);
    // Listen to playback state changes to rebuild UI reliably (BUG FIX)
    ctrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _disposeDistantControllers(int currentIndex) {
    final toDispose =
        _controllers.keys.where((k) => (k - currentIndex).abs() > 2).toList();
    for (final k in toDispose) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }
  }

  void _incrementViewCount(int index) {
    final videoId = widget.videos[index].id;
    if (_viewedIds.contains(videoId)) return;
    _viewedIds.add(videoId);
    // Fire-and-forget — non-critical
    ref.read(videoRepositoryProvider).incrementView(videoId);
  }

  // ── Page change ────────────────────────────────────────────────────────────

  Future<void> _onPageChanged(int index) async {
    _controllers[_currentIndex]?.pause();
    setState(() => _currentIndex = index);
    await _initPage(index);
  }

  // ── Play / Pause (BUG FIX: single source of truth via controller.value) ────

  void _togglePlayPause() {
    final ctrl = _controllers[_currentIndex];
    if (ctrl == null || !ctrl.value.isInitialized) return;
    setState(() {
      ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
    });
  }

  void _toggleOverlay() => setState(() => _showOverlay = !_showOverlay);

  // ── Double-tap seek ────────────────────────────────────────────────────────

  Future<void> _seekBy(Duration delta) async {
    final ctrl = _controllers[_currentIndex];
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final current = ctrl.value.position;
    final total = ctrl.value.duration;
    final target = current + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > total
            ? total
            : target;
    await ctrl.seekTo(clamped);
    if (mounted) setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final video = widget.videos[index];
          final ctrl = _controllers[index];
          final isActive = index == _currentIndex;
          final isPlaying = ctrl?.value.isPlaying ?? false;

          return GestureDetector(
            onTap: _toggleOverlay,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Video layer ──────────────────────────────────────────────
                _VideoLayer(controller: ctrl),

                // ── Double-tap zones ─────────────────────────────────────────
                if (isActive) ...[
                  // Left zone — seek -10s
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: _DoubleTapSeekZone(
                      onDoubleTap: () => _seekBy(const Duration(seconds: -10)),
                      direction: SeekDirection.backward,
                    ),
                  ),
                  // Right zone — seek +10s
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: _DoubleTapSeekZone(
                      onDoubleTap: () => _seekBy(const Duration(seconds: 10)),
                      direction: SeekDirection.forward,
                    ),
                  ),
                ],

                // ── Centre tap-to-play/pause ─────────────────────────────────
                // Only the centre 30% of width triggers play/pause
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.30,
                    height: double.infinity,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: isActive ? _togglePlayPause : null,
                      child: AnimatedOpacity(
                        opacity: (isActive && !isPlaying) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Center(child: _PauseIndicator()),
                      ),
                    ),
                  ),
                ),

                // ── Top bar ──────────────────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopBar(
                    visible: _showOverlay,
                    video: video,
                  ),
                ),

                // ── Bottom meta ──────────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _VideoMeta(
                    video: video,
                    controller: isActive ? ctrl : null,
                    visible: _showOverlay,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _VideoLayer extends StatelessWidget {
  const _VideoLayer({this.controller});
  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller!.value.size.width,
        height: controller!.value.size.height,
        child: VideoPlayer(controller!),
      ),
    );
  }
}

class _PauseIndicator extends StatelessWidget {
  const _PauseIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child:
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
    );
  }
}

// ── Double-tap seek zone ──────────────────────────────────────────────────────

enum SeekDirection { forward, backward }

class _DoubleTapSeekZone extends StatefulWidget {
  const _DoubleTapSeekZone({
    required this.onDoubleTap,
    required this.direction,
  });

  final VoidCallback onDoubleTap;
  final SeekDirection direction;

  @override
  State<_DoubleTapSeekZone> createState() => _DoubleTapSeekZoneState();
}

class _DoubleTapSeekZoneState extends State<_DoubleTapSeekZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _visible = false);
        }
      });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    widget.onDoubleTap();
    setState(() => _visible = true);
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isForward = widget.direction == SeekDirection.forward;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: _handleDoubleTap,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isForward ? Alignment.centerRight : Alignment.centerLeft,
              end: isForward ? Alignment.centerLeft : Alignment.centerRight,
              colors: [Colors.white.withOpacity(0.15), Colors.transparent],
            ),
            borderRadius: BorderRadius.horizontal(
              left: isForward ? Radius.zero : const Radius.circular(80),
              right: isForward ? const Radius.circular(80) : Radius.zero,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isForward
                      ? Icons.fast_forward_rounded
                      : Icons.fast_rewind_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 4),
                Text(
                  isForward ? '+10s' : '-10s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.visible, required this.video});
  final bool visible;
  final Video video;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          left: 4,
          right: 4,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xAA000000), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 22),
              onPressed: () => Navigator.maybePop(context),
            ),
            const Spacer(),
            // Save button in top bar
            SaveButton(video: video),
          ],
        ),
      ),
    );
  }
}

// ── Bottom meta ───────────────────────────────────────────────────────────────

class _VideoMeta extends StatelessWidget {
  const _VideoMeta({
    required this.video,
    required this.controller,
    required this.visible,
  });

  final Video video;
  final VideoPlayerController? controller;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 40,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (video.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                video.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  TimeUtils.timeAgo(video.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.visibility_outlined,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  video.viewsDisplay,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            if (controller != null && controller!.value.isInitialized) ...[
              const SizedBox(height: 12),
              VideoProgressIndicator(
                controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFE94560),
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
