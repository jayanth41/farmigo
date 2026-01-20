import 'dart:async';

import 'package:flutter/material.dart';

/// Simple data model for an offer card.
class OfferItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const OfferItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

/// Reusable OfferCard widget (UI only).
class OfferCard extends StatelessWidget {
  final OfferItem offer;
  final double borderRadius;

  const OfferCard({super.key, required this.offer, this.borderRadius = 14.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: offer.color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(offer.icon, size: 28, color: Colors.white),
          const Spacer(),
          Text(
            offer.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            offer.subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// OffersCarousel: auto-scrolling PageView with infinite loop and indicators.
class OffersCarousel extends StatefulWidget {
  final List<OfferItem> offers;
  final double height;
  final Duration autoScrollDelay;

  const OffersCarousel({
    super.key,
    required this.offers,
    this.height = 140,
    this.autoScrollDelay = const Duration(seconds: 3),
  }) : assert(offers.length > 0, 'offers must not be empty');

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  late final PageController _pageController;
  Timer? _autoTimer;
  bool _isUserInteracting = false;
  int _currentIndex = 0;

  int get _realCount => widget.offers.length;

  // start in the middle so user can scroll backwards/forwards for illusion of infinite
  int get _initialPage => _realCount * 1000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.86, initialPage: _initialPage);
    _currentIndex = _initialPage % _realCount;
    _pageController.addListener(_onPageChanged);
    _startAutoScroll();
  }

  void _onPageChanged() {
    final page = _pageController.page;
    if (page == null) return;
    final int newIndex = page.round() % _realCount;
    if (newIndex != _currentIndex) {
      setState(() => _currentIndex = newIndex);
    }
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(widget.autoScrollDelay, (_) {
      if (_isUserInteracting || !mounted) return;
      final next = _pageController.page?.round() ?? _pageController.initialPage;
      final target = next + 1;
      _pageController.animateToPage(target, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  void _pauseAutoScroll() {
    _isUserInteracting = true;
  }

  void _resumeAutoScrollDelayed() {
    _isUserInteracting = false;
    // restart timer to ensure delay resets
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _pauseAutoScroll();
              } else if (notification is ScrollEndNotification) {
                // give a short delay before resuming to avoid immediate jump
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _resumeAutoScrollDelayed();
                });
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                final int itemIndex = index % _realCount;
                final offer = widget.offers[itemIndex];
                return Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.86,
                    child: OfferCard(offer: offer),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_realCount, (i) {
        final bool active = i == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.black87 : Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
