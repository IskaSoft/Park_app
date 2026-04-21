import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/time_utils.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  final List<Video> videos;
  final int initialIndex;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final PageController _pageController;
  // One controller slot per page; lazy-init on demand.
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _preload(_currentIndex);
  }

  // Pre-initialize current + next to ensure smooth transitions.
  Future<void> _preload(int index) async {
    for (final i in [index, index + 1]) {
      if (i < 0 || i >= widget.videos.length) continue;
      if (_controllers.containsKey(i)) continue;

      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.videos[i].fileUrl),
      );
      _controllers[i] = ctrl;
      await ctrl.initialize();
      ctrl.setLooping(true);
      if (i == index) {
        ctrl.play();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _onPageChanged(int index) async {
    // Pause previous
    _controllers[_currentIndex]?.pause();
    setState(() => _currentIndex = index);
    await _preload(index);
    _controllers[index]?.play();

    // Dispose controllers that are far away to free memory
    final toDispose = _controllers.keys
        .where((k) => (k - index).abs() > 2)
        .toList();
    for (final k in toDispose) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }
  }

  void _toggleControls() =>
      setState(() => _showControls = !_showControls);

  void _togglePlayPause() {
    final ctrl = _controllers[_currentIndex];
    if (ctrl == null) return;
    setState(() {
      ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
    });
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

          return GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video
                _VideoLayer(controller: ctrl),

                // Tap-to-pause overlay
                if (isActive && ctrl != null && !ctrl.value.isPlaying)
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      color: Colors.transparent,
                      child: const Center(
                        child: _PauseIndicator(),
                      ),
                    ),
                  ),

                // Top bar (back button)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopBar(visible: _showControls),
                ),

                // Bottom metadata overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _VideoMeta(
                    video: video,
                    controller: ctrl,
                    visible: _showControls,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
        child: CircularProgressIndicator(
          color: Colors.white54,
          strokeWidth: 2,
        ),
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xAA000000), Colors.transparent],
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 22),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}

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
          top: 32,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [0.0, 1.0],
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              TimeUtils.timeAgo(video.createdAt),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
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
