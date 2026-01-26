import 'dart:async';
import 'package:flutter/material.dart';

/// Offer data model
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

/// Single offer card
class OfferCard extends StatelessWidget {
  final OfferItem offer;

  const OfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: offer.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(offer.icon, size: 30, color: Colors.white),
          const Spacer(),
          Text(
            offer.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            offer.subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carousel widget
class OffersCarousel extends StatefulWidget {
  final List<OfferItem> offers;
  final double height;

  const OffersCarousel({
    super.key,
    required this.offers,
    this.height = 140,
  });

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Auto scroll every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      int nextPage = _currentIndex + 1;
      if (nextPage == widget.offers.length) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.offers.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return OfferCard(offer: widget.offers[index]);
            },
          ),
        ),
        const SizedBox(height: 10),

        // DOT INDICATORS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.offers.length, (index) {
            final bool active = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 14 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}
