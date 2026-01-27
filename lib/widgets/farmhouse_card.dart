import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
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
    if (wasFav) {
      await favoritesController.removeFavorite(farmhouse.id);
    } else {
      await favoritesController.addFavorite(farmhouse);
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = favoritesController.isFavorited(widget.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                (widget.category.toLowerCase().contains('farm'))
                    ? FarmhouseDetailsScreen(
                        name: widget.name,
                        location: widget.location,
                        price: widget.price,
                        distance: widget.distance ?? '',
                        imageUrl: widget.image,
                        images: widget.images,
                        id: widget.id,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${widget.discount}% OFF",
                        style: const TextStyle(
                            color: Colors.white,
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // DETAILS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(widget.location,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.rating} (${widget.reviews})",
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        "₹${widget.price.toInt()}",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      const Text("/night",
                          style: TextStyle(fontSize: 12)),
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
