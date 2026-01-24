import 'dart:async';
import 'package:flutter/material.dart';
import 'image_with_fallback.dart';

class FarmhouseImageSlider extends StatefulWidget {
  final List<String> images;
  final double height;

  const FarmhouseImageSlider({
    super.key,
    required this.images,
    this.height = 240,
  });

  @override
  State<FarmhouseImageSlider> createState() => _FarmhouseImageSliderState();
}

class _FarmhouseImageSliderState extends State<FarmhouseImageSlider> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;
  bool _userTouching = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    if (widget.images.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_userTouching || !_pageController.hasClients) return;

      _currentIndex =
          (_currentIndex + 1) % widget.images.length;

      _pageController.animateToPage(
        _currentIndex,
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
    if (widget.images.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return GestureDetector(
      onPanDown: (_) => _userTouching = true,
      onPanCancel: () => _userTouching = false,
      onPanEnd: (_) => _userTouching = false,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemBuilder: (context, index) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _currentIndex == index ? 1.0 : 0.0,
              child: ImageWithFallback(
                imageUrl: widget.images[index],
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ),
    );
  }
}
