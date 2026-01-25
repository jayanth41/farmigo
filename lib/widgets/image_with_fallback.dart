import 'package:flutter/material.dart';

/// A small, reusable image widget that attempts to load a network image and
/// shows a graceful fallback (placeholder) when loading fails.
///
/// This centralizes logging and loading UI so the rest of the app can rely
/// on a consistent behavior even when emulator/device networking is flaky.
class ImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  const ImageWithFallback({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      // show a loading indicator while the image is loading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        final expected = loadingProgress.expectedTotalBytes ?? 0;
        final received = loadingProgress.cumulativeBytesLoaded;
        debugPrint('Image loading: $imageUrl ($received/$expected)');
        return Container(
          height: height,
          width: width,
          color: const Color.fromRGBO(240, 240, 240, 1.0),
          child: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image.network error for $imageUrl: $error');
        if (stackTrace != null) debugPrint('$stackTrace');
        // Simple, consistent grey placeholder with an icon.
        return Container(
          height: height,
          width: width,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported,
            size: 60,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}
