// lib/features/saved/presentation/saved_videos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../saved_videos_service.dart';
import '../../../shared/widgets/video_thumbnail_card.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../videos/presentation/video_player_screen.dart';

class SavedVideosScreen extends ConsumerWidget {
  const SavedVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedVideosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saklanan Wideolar'),
        actions: [
          if (saved.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, ref),
              child: const Text(
                'Hemmesini öçür',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
        ],
      ),
      body: saved.isEmpty
          ? const EmptyStateWidget(
              message: 'Saklanan wideo ýok.\nWideo oýnadyňyzda ⊕ düwmä basyň.',
              icon: Icons.bookmark_outline_rounded,
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: saved.length,
              itemBuilder: (context, index) {
                return VideoThumbnailCard(
                  video: saved[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        videos: saved,
                        initialIndex: index,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hemmesini öçürmeli mi?'),
        content: const Text('Ähli saklanan wideolar ýok ediler.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ýok'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Öçür'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final notifier = ref.read(savedVideosProvider.notifier);
      final ids = ref.read(savedVideosProvider).map((v) => v.id).toList();
      for (final id in ids) {
        await notifier.remove(id);
      }
    }
  }
}
