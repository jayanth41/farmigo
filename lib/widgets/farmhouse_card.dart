import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/farmhouse_model.dart';
import '../controllers/favorites_controller.dart';
import '../screens/farmhouse_details_screen.dart';

class FarmhouseCard extends StatefulWidget {
  final String name;
  final String location;
  final double price;
  final String distance;
  final String imageUrl;
  final List<String>? images;
  final String? id;

  const FarmhouseCard({
    super.key,
    required this.name,
    required this.location,
    required this.price,
    required this.distance,
    required this.imageUrl,
    this.images,
    this.id,
  });

  @override
  State<FarmhouseCard> createState() => _FarmhouseCardState();
}
// Removed Markdown code fence marker
class _FarmhouseCardState extends State<FarmhouseCard>
    with SingleTickerProviderStateMixin {
  bool isFav = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  FavoritesController? _favController;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween(begin: 1.0, end: 1.2).animate(_controller);

    // lazy register favorites controller if not present
    if (Get.isRegistered<FavoritesController>()) {
      _favController = Get.find<FavoritesController>();
      isFav = _favController!.isFavorited(widget.id ?? widget.name);
    } else {
      // avoid creating it if you don't want global state; keeping safe fallback
      try {
  _favController = Get.put(FavoritesController());
  isFav = _favController!.isFavorited(widget.id ?? widget.name);
      } catch (_) {
        _favController = null;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFav() {
    setState(() => isFav = !isFav);
    _controller.forward().then((_) => _controller.reverse());
    if (_favController != null) {
      final farmhouse = FarmhouseModel(
        id: widget.id ?? widget.name,
        name: widget.name,
        location: widget.location,
        price: widget.price,
        distance: widget.distance,
        imageUrl: widget.imageUrl,
        images: widget.images ?? [],
      );

      if (isFav) {
        _favController!.addFavorite(farmhouse);
      } else {
        _favController!.removeFavorite(farmhouse.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // navigate to details
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FarmhouseDetailsScreen(
                  name: widget.name,
                  location: widget.location,
                  price: widget.price,
                  distance: widget.distance,
                  imageUrl: widget.imageUrl,
                  images: widget.images,
                  id: widget.id ?? widget.name,
                )));
      },
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1B5E20), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.12),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    widget.imageUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                      // show a loading indicator while the image is loading
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        final expected = loadingProgress.expectedTotalBytes ?? 0;
                        final received = loadingProgress.cumulativeBytesLoaded;
                        debugPrint('Image loading: ${widget.imageUrl} ($received/$expected)');
                        return Container(
                          height: 210,
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
                        // Log the error for diagnosis
                        debugPrint('Image.network error for ${widget.imageUrl}: $error');
                        if (stackTrace != null) debugPrint('$stackTrace');
                        return Container(
                          height: 210,
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
                  ),
                ),

                // GRADIENT OVERLAY
                Container(
                  height: 210,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color.fromRGBO(0, 0, 0, 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // RATING
                const Positioned(
                  top: 12,
                  left: 12,
                  child: _RatingPill(rating: 4.6),
                ),

                // FAVORITE
                Positioned(
                  top: 12,
                  right: 12,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: GestureDetector(
                      onTap: () {
                        _toggleFav();
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                // TITLE
                Positioned(
                  left: 12,
                  bottom: 18,
                  right: 12,
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📍 ${widget.location} • ${widget.distance}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  const Text("👨‍👩‍👧‍👦 Up to 6 guests"),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PRICE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹${widget.price.toInt().toString()}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const Text(
                            "per night",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),

                      // CTA
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => FarmhouseDetailsScreen(
                                    name: widget.name,
                                    location: widget.location,
                                    price: widget.price,
                                    distance: widget.distance,
                                    imageUrl: widget.imageUrl,
                                    images: widget.images,
                                    id: widget.id ?? widget.name,
                                  )));
                        },
                        child: const Text("View Details"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '⭐ ${rating.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
// Removed Markdown code fence marker
