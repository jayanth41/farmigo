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
    // Get the FavoritesController
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    favoritesController = Get.find<FavoritesController>();
  }

  void _toggleFavorite() async {
    // Create a FarmhouseModel from the card data
    final farmhouse = FarmhouseModel(
      id: widget.name,
      name: widget.name,
      location: widget.location,
      price: widget.price,
      distance: widget.distance ?? '0 km',
      imageUrl: widget.image,
      images: widget.images ?? [],
    );
    
    if (favoritesController.isFavorited(farmhouse.id)) {
      await favoritesController.removeFavorite(farmhouse.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.name} removed from favorites'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      await favoritesController.addFavorite(farmhouse);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.name} added to favorites'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = widget.name;
    final isFavorite = favoritesController.isFavorited(propertyId);

    return GestureDetector(
      onTap: () {
        // Navigate to a generic booking/details screen that adapts to category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                // Use the specific farmhouse details screen for farmhouses for now
                (widget.category.toLowerCase().contains('farm'))
                    ? FarmhouseDetailsScreen(
                        name: widget.name,
                        location: widget.location,
                        price: widget.price,
                        distance: widget.distance ?? '',
                        imageUrl: widget.image,
                        images: widget.images,
                        id: widget.name,
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
        width: 340,
        margin: const EdgeInsets.only(right: 16, bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: ImageWithFallback(
                    imageUrl: widget.image,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (widget.discount != null) 
                  Positioned(top: 12, left: 12, child: _discountBadge("${widget.discount}% OFF")),
                
                // Favorite Heart Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? Colors.red : AppColors.textMuted,
                      ),
                    ),
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
                    widget.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Small reviews subtext
                  Text(
                    '${widget.reviews} reviews',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Rating stars
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          final filled = i < widget.rating.round();
                          return Icon(
                            Icons.star,
                            size: 12,
                            color: filled ? Colors.amber : Colors.grey[300],
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.reviews})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Amenities
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.amenities
                        .take(3)
                        .map((a) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.chipBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  
                  // Price and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ratingPill(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${widget.price.toInt()}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const Text(
                            "per night",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
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

  Widget _discountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _ratingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ratingBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            "${widget.rating}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            " (${widget.reviews})",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}