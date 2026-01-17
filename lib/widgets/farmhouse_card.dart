import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/farmhouse_details_screen.dart';
import '../screens/booking_details_screen.dart';
import 'image_with_fallback.dart';

class FarmhouseCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to a generic booking/details screen that adapts to category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                // Use the specific farmhouse details screen for farmhouses for now
                (category.toLowerCase().contains('farm'))
                    ? FarmhouseDetailsScreen(
                        name: name,
                        location: location,
                        price: price,
                        distance: distance ?? '',
                        imageUrl: image,
                        images: images,
                        id: name,
                      )
                    : BookingDetailsScreen(
                        name: name,
                        category: category,
                        location: location,
                        price: price,
                        rating: rating,
                        reviews: reviews,
                        imageUrl: image,
                        amenities: amenities,
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
                    imageUrl: image,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (discount != null) Positioned(top: 12, left: 12, child: _discountBadge("$discount% OFF")),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]),
                    child: const Icon(Icons.favorite_border, size: 18, color: AppColors.textMuted),
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
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  // Small reviews subtext
                  Text(
                    '$reviews reviews',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Row(children: List.generate(5, (i) {
                        final filled = i < rating.round();
                        return Icon(Icons.star, size: 12, color: filled ? Colors.amber : Colors.grey[300]);
                      })),
                      const SizedBox(width: 8),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('($reviews)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(child: Text(location, style: const TextStyle(fontSize: 13, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: amenities.take(3).map((a) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(20)), child: Text(a, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500)))).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _ratingPill(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text("₹${price.toInt()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                      const Text("per night", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ])
                  ])
                ],
              ),
            )
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
            "$rating",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            " ($reviews)",
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

// Example horizontal list (if needed in a parent widget):
// SizedBox(
//   height: 380,
//   child: ListView(
//     scrollDirection: Axis.horizontal,
//     padding: const EdgeInsets.only(left: 16),
//     children: const [
//       FarmhouseCard(
//         image: "https://images.unsplash.com/photo-1564013799919-ab600027ffc6",
//         name: "Green Valley Farmhouse",
//         location: "Lonavala, Maharashtra",
//         price: 8500,
//         rating: 4.8,
//         reviews: 245,
//         amenities: ["Pool", "BBQ", "Garden"],
//         discount: 20,
//       ),
//       FarmhouseCard(
//         image: "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85",
//         name: "Riverside Retreat",
//         location: "Karjat, Maharashtra",
//         price: 6200,
//         rating: 4.6,
//         reviews: 189,
//         amenities: ["River View", "Bonfire", "Parking"],
//         discount: 15,
//       ),
//     ],
//   ),
// ),
