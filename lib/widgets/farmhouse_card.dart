import 'dart:async';
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
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Container(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 6),
    ],
  ),
  child: Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageWithFallback(
          imageUrl: widget.image,
          height: 110,
          width: 120,
          fit: BoxFit.cover,
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),

            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
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
                const Icon(Icons.star, size: 14, color: Colors.orange),
                Text("${widget.rating} (${widget.reviews})"),
              ],
            ),
          ],
        ),
      ),

      Column(
        children: [
          Text(
            "₹${widget.price.toInt()}",
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const Text("/night", style: TextStyle(fontSize: 12)),
        ],
      ),
    ],
  ),
),

      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
