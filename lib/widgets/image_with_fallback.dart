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
        // Attempt to show a local asset fallback if you add one at
        // assets/images/fallback.png. If that asset is missing we'll
        // still show a simple placeholder that won't crash.
        return Container(
          height: height,
          width: width,
          color: const Color.fromRGBO(200, 200, 200, 1.0),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.broken_image, size: 48, color: Colors.black54),
              SizedBox(height: 8),
              Text('Image unavailable', style: TextStyle(color: Colors.black54)),
            ],
          ),
        );
      },
    );
  }
}
