import 'package:flutter/material.dart';
import 'image_with_fallback.dart';

class FarmhouseImageSlider extends StatefulWidget {
  final List<String> images;

  const FarmhouseImageSlider({
    super.key,
    required this.images,
  });

  @override
  State<FarmhouseImageSlider> createState() => _FarmhouseImageSliderState();
}

class _FarmhouseImageSliderState extends State<FarmhouseImageSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemBuilder: (context, index) {
            return ImageWithFallback(
              imageUrl: widget.images[index],
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            );
          },
        ),

        // 🔹 Dots Indicator
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 10 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Colors.white
                      : Colors.white54,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
