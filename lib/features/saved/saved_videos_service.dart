// lib/features/saved/saved_videos_service.dart
//
// Architecture note:
// SharedPreferences stores a JSON list of saved video objects.
// We use Video.toJson() / Video.fromJson() for serialization.
// This lives in its own service class — nothing else knows about
// SharedPreferences — so swapping to SQLite later is trivial.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/models.dart';

const _kSavedKey = 'saved_videos';

// ── Provider ──────────────────────────────────────────────────────────────────

final savedVideosProvider =
    StateNotifierProvider<SavedVideosNotifier, List<Video>>(
  (ref) => SavedVideosNotifier(),
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class SavedVideosNotifier extends StateNotifier<List<Video>> {
  SavedVideosNotifier() : super([]) {
    _load();
  }

  // Load saved videos from local storage on startup
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedKey) ?? [];
    state = raw
        .map((s) => Video.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((v) => json.encode(v.toJson())).toList();
    await prefs.setStringList(_kSavedKey, raw);
  }

  bool isSaved(int videoId) => state.any((v) => v.id == videoId);

  Future<void> toggle(Video video) async {
    if (isSaved(video.id)) {
      state = state.where((v) => v.id != video.id).toList();
    } else {
      state = [video, ...state];
    }
    await _persist();
  }

  Future<void> remove(int videoId) async {
    state = state.where((v) => v.id != videoId).toList();
    await _persist();
  }
}
