// lib/features/videos/presentation/video_player_screen.dart
// REPLACE entire file.
//
// Fix 1 — Landscape videos (YouTube 16:9):
//   Portrait  → FittedBox + cover  (fills screen, slight side crop — TikTok style)
//   Landscape → AspectRatio + contain (letterbox, shows full video — no cropping)
//
// Fix 2 — No internet / blank screen:
//   Handled in categories_screen.dart (see that file).
//
// All previous fixes retained.

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
  final Set<int> _viewedIds = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initPage(_currentIndex);
  }

  Future<void> _initPage(int index) async {
    if (index < 0 || index >= widget.videos.length) return;
    for (final i in [index, index + 1]) {
      if (i < 0 || i >= widget.videos.length) continue;
      if (!_controllers.containsKey(i)) await _createController(i);
    }
    final ctrl = _controllers[index];
    if (ctrl != null && ctrl.value.isInitialized) {
      await ctrl.seekTo(Duration.zero);
      await ctrl.play();
      if (mounted) setState(() {});
    }
    _recordView(index);
    _disposeDistant(index);
  }

  Future<void> _createController(int index) async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.videos[index].fileUrl),
    );
    _controllers[index] = ctrl;
    await ctrl.initialize();
    ctrl.setLooping(true);
    ctrl.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _disposeDistant(int current) {
    final keys =
        _controllers.keys.where((k) => (k - current).abs() > 2).toList();
    for (final k in keys) {
      _controllers[k]?.removeListener(_onControllerUpdate);
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }
  }

  void _recordView(int index) {
    final id = widget.videos[index].id;
    if (_viewedIds.contains(id)) return;
    _viewedIds.add(id);
    ref.read(videoRepositoryProvider).incrementView(id);
  }

  Future<void> _onPageChanged(int index) async {
    _controllers[_currentIndex]?.pause();
    setState(() => _currentIndex = index);
    await _initPage(index);
  }

  void _togglePlayPause() {
    final ctrl = _controllers[_currentIndex];
    if (ctrl == null || !ctrl.value.isInitialized) return;
    ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
  }

  void _toggleOverlay() => setState(() => _showOverlay = !_showOverlay);

  Future<void> _seekBy(Duration delta) async {
    final ctrl = _controllers[_currentIndex];
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final current = ctrl.value.position;
    final total = ctrl.value.duration;
    final raw = current + delta;
    final target = raw < Duration.zero
        ? Duration.zero
        : raw > total
            ? total
            : raw;
    await ctrl.seekTo(target);
  }

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
          final isInitialized = ctrl?.value.isInitialized ?? false;
          final isPlaying = ctrl?.value.isPlaying ?? false;

          return GestureDetector(
            onTap: _toggleOverlay,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Smart video (portrait cover / landscape contain) ─────────
                _SmartVideoLayer(controller: isInitialized ? ctrl : null),

                // ── Loading spinner ──────────────────────────────────────────
                if (!isInitialized)
                  const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white38, strokeWidth: 2),
                  ),

                // ── Seek zones ───────────────────────────────────────────────
                if (isActive) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: _SeekZone(
                      direction: _SeekDirection.backward,
                      onDoubleTap: () => _seekBy(const Duration(seconds: -10)),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: _SeekZone(
                      direction: _SeekDirection.forward,
                      onDoubleTap: () => _seekBy(const Duration(seconds: 10)),
                    ),
                  ),
                ],

                // ── Play/pause tap ───────────────────────────────────────────
                if (isActive)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _togglePlayPause,
                      child: AnimatedOpacity(
                        opacity: (!isPlaying && isInitialized) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: const Center(child: _PauseIndicator()),
                      ),
                    ),
                  ),

                // ── Top bar ──────────────────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopBar(visible: _showOverlay, video: video),
                ),

                // ── Bottom meta ──────────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BottomMeta(
                    video: video,
                    controller: isActive && isInitialized ? ctrl : null,
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
      ctrl.removeListener(_onControllerUpdate);
      ctrl.dispose();
    }
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart Video Layer — THE KEY FIX
//
// Portrait (height > width): TikTok-style cover — fills screen.
// Landscape (width > height): YouTube-style contain — no cropping, letterbox.
// ─────────────────────────────────────────────────────────────────────────────

class _SmartVideoLayer extends StatelessWidget {
  const _SmartVideoLayer({this.controller});
  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null) return const SizedBox.expand();

    final size = controller!.value.size;
    final isLandscape = size.width > size.height;

    return SizedBox.expand(
      child: isLandscape
          // Landscape: show full video, letterbox (black top/bottom)
          ? Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            )
          // Portrait: cover full screen (TikTok style)
          : FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(controller!),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PauseIndicator extends StatelessWidget {
  const _PauseIndicator();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child:
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
    );
  }
}

enum _SeekDirection { forward, backward }

class _SeekZone extends StatefulWidget {
  const _SeekZone({required this.direction, required this.onDoubleTap});
  final _SeekDirection direction;
  final VoidCallback onDoubleTap;
  @override
  State<_SeekZone> createState() => _SeekZoneState();
}

class _SeekZoneState extends State<_SeekZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
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
    final isForward = widget.direction == _SeekDirection.forward;
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
              colors: [Colors.white.withOpacity(0.18), Colors.transparent],
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
                  size: 38,
                ),
                const SizedBox(height: 4),
                Text(
                  isForward ? '+10s' : '-10s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
          right: 8,
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
            SaveButton(video: video),
          ],
        ),
      ),
    );
  }
}

class _BottomMeta extends StatelessWidget {
  const _BottomMeta({
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
            Text(video.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            if (video.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(video.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(TimeUtils.timeAgo(video.createdAt),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.visibility_outlined,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(video.viewsDisplay,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            if (controller != null) ...[
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
