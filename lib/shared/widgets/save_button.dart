// lib/shared/widgets/save_button.dart
// No changes needed — already correct.
// Included here for completeness.
//
// This widget is used in VideoPlayerScreen top bar.
// It reads from savedVideosProvider and syncs with grid automatically
// because both use the same Riverpod provider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../features/saved/saved_videos_service.dart';

class SaveButton extends ConsumerStatefulWidget {
  const SaveButton({
    super.key,
    required this.video,
    this.size = 26,
    this.color = Colors.white,
  });

  final Video video;
  final double size;
  final Color color;

  @override
  ConsumerState<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await ref.read(savedVideosProvider.notifier).toggle(widget.video);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = ref.watch(
      savedVideosProvider
          .select((list) => list.any((v) => v.id == widget.video.id)),
    );

    return ScaleTransition(
      scale: _scaleAnim,
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            key: ValueKey(isSaved),
            color: isSaved ? Colors.amber : widget.color,
            size: widget.size,
          ),
        ),
        onPressed: _onTap,
        tooltip: isSaved ? 'Saklandy' : 'Sakla',
      ),
    );
  }
}
