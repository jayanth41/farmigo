import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/farmhouse_details_screen.dart';
import '../screens/booking_details_screen.dart';
import '../controllers/favorites_controller.dart';
import '../models/farmhouse_model.dart';
import 'image_with_fallback.dart';

class FarmhouseCard extends StatefulWidget {
  final String image;
  final String id;
  final String name;
  final String location;
  final String category;
  final double price;
  final double rating;
  final int reviews;
  final List<String> amenities;
  final int? discount;
  final String? distance;
  final List<String>? images;

  const FarmhouseCard({
    super.key,
    String? image,
    String? imageUrl,
    this.category = 'Farmhouses',
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    this.rating = 0.0,
    this.reviews = 0,
    List<String>? amenities,
    this.discount,
    this.distance,
    this.images,
  })  : image = image ?? imageUrl ?? '',
        amenities = amenities ?? const [];

  @override
  State<FarmhouseCard> createState() => _FarmhouseCardState();
}

class _FarmhouseCardState extends State<FarmhouseCard> {
  late FavoritesController favoritesController;
  bool? _optimisticFavorite;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    favoritesController = Get.find<FavoritesController>();
  }

  void _toggleFavorite() async {
    final farmhouse = FarmhouseModel(
      id: widget.id,
      name: widget.name,
      location: widget.location,
      price: widget.price,
      distance: widget.distance ?? '0 km',
      imageUrl: widget.image,
      images: widget.images ?? [],
    );

    final wasFav = favoritesController.isFavorited(farmhouse.id);
    // Optimistic UI update: show immediate change while controller handles persistence
    _optimisticFavorite = !wasFav;
    if (mounted) setState(() {});

    if (wasFav) {
      await favoritesController.removeFavorite(farmhouse.id);
    } else {
      await favoritesController.addFavorite(farmhouse);
    }

    // Clear optimistic flag and refresh
    _optimisticFavorite = null;
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
  final isFavoriteRemote = favoritesController.isFavorited(widget.id);
  final isFavorite = _optimisticFavorite ?? isFavoriteRemote;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
                builder: (_) => (widget.category.toLowerCase().contains('farm'))
                    ? FarmhouseDetailsScreen(
                        name: widget.name,
                        location: widget.location,
                        price: widget.price,
                        distance: widget.distance ?? '0 km',
                        imageUrl: widget.image,
                        images: widget.images,
                        id: widget.id,
                        ownerId: null,
                      )
                    : BookingDetailsScreen(
                        name: widget.name,
                        category: widget.category,
                        location: widget.location,
                        price: widget.price,
                        rating: widget.rating,
                        reviews: widget.reviews,
                        imageUrl: widget.image,
                        amenities: widget.amenities,
                      ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color:  Color.fromARGB(255, 41, 70, 92), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE PART
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: ImageWithFallback(
                    imageUrl: widget.image,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // DISCOUNT BADGE
                if (widget.discount != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${widget.discount}% OFF",
                        style: TextStyle(
                            // Use onPrimary for readable text on primary-colored badge
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),

                // FAVORITE ICON
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // DETAILS (moved into a primary-colored footer for better contrast)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.95)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.orange.shade200),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.rating} (${widget.reviews})",
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.95)),
                      ),
                      const Spacer(),
                      Text(
                        "₹${widget.price.toInt()}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "/night",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.95)),
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