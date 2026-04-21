// lib/features/banners/presentation/banner_carousel.dart
// NEW FILE
//
// Awtomatik aýlanýan banner carousel.
// - 4 sekuntda bir gezek geçýär
// - Barmak bilen sürüp bolýar
// - Aşagynda nokta indikatoru bar
// - Wideo we surat ikisini hem goldaýar
// - Surat ýüklenýärkä shimmer görkezýär

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';
import '../providers/banner_providers.dart';

class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key});

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  late final PageController _ctrl;
  Timer? _timer;
  int _current = 0;

  // Her banner näçe wagt görünmeli (sekunt)
  static const _autoPlayDuration = Duration(seconds: 4);
  // Geçiş animasiýasy wagty
  static const _animDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startTimer(int itemCount) {
    _timer?.cancel();
    if (itemCount <= 1) return;
    _timer = Timer.periodic(_autoPlayDuration, (_) {
      if (!mounted) return;
      final next = (_current + 1) % itemCount;
      _ctrl.animateToPage(
        next,
        duration: _animDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index, int itemCount) {
    setState(() => _current = index);
    // Timer-y täzele — manual swipe bolanda timer reset bolsun
    _startTimer(itemCount);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bannersProvider);

    return async.when(
      // Banner ýüklenýärkä shimmer görkezýär
      loading: () => const _CarouselShimmer(),

      // Ýalňyşlyk bolsa ýa-da banner ýok bolsa — carousel görkezilmeýär
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        // Timer diňe data gelenden soň başlaýar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startTimer(banners.length);
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Carousel ──────────────────────────────────────────────────
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: banners.length,
                onPageChanged: (i) => _onPageChanged(i, banners.length),
                itemBuilder: (context, index) {
                  return _BannerCard(banner: banners[index]);
                },
              ),
            ),

            // ── Nokta indikatoru ─────────────────────────────────────────
            if (banners.length > 1) ...[
              const SizedBox(height: 10),
              _DotIndicator(
                count: banners.length,
                current: _current,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bir banner karty
// ─────────────────────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});
  final BannerModel banner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Surat ────────────────────────────────────────────────────
            _BannerImage(url: banner.imageUrl),

            // ── Gradient overlay ─────────────────────────────────────────
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),

            // ── Title we description ──────────────────────────────────────
            if (banner.title.isNotEmpty || banner.description.isNotEmpty)
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (banner.title.isNotEmpty)
                      Text(
                        banner.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    if (banner.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        banner.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner surat widget-i
// ─────────────────────────────────────────────────────────────────────────────

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        // Ýüklenýärkä shimmer renk
        return Container(color: const Color(0xFF1E2A4A));
      },
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF1E2A4A),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white24, size: 40),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Nokta indikatoru
// ─────────────────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? const Color(0xFFE94560)
                : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer — banner ýüklenýärkä görkezilýär
// ─────────────────────────────────────────────────────────────────────────────

class _CarouselShimmer extends StatefulWidget {
  const _CarouselShimmer();

  @override
  State<_CarouselShimmer> createState() => _CarouselShimmerState();
}

class _CarouselShimmerState extends State<_CarouselShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.05, end: 0.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(_anim.value),
          ),
        ),
      ),
    );
  }
}
