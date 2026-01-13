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

class _FarmhouseCardState extends State<FarmhouseCard> {
  late FavoritesController favoritesController;
  late FarmhouseModel farmhouse;

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }

    favoritesController = Get.find<FavoritesController>();

    farmhouse = FarmhouseModel(
      id: widget.id ?? widget.name,
      name: widget.name,
      location: widget.location,
      price: widget.price,
      distance: widget.distance,
      imageUrl: widget.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.images != null && widget.images!.isNotEmpty)
        ? widget.images!
        : [widget.imageUrl];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ================= IMAGE SLIDER (SWIPE ENABLED) =================
            SizedBox(
              height: 240,
              width: double.infinity,
              child: PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 60),
                    ),
                  );
                },
              ),
            ),

            // ================= DOT INDICATOR =================
            if (images.length > 1)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 10 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

            // ================= DARK GRADIENT (DO NOT BLOCK TOUCH) =================
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ================= FAVORITE BUTTON =================
            Positioned(
              top: 12,
              right: 12,
              child: Obx(() {
                final isFav =
                    favoritesController.isFavorited(farmhouse.id);
                return GestureDetector(
                  onTap: () {
                    favoritesController.toggleFavorite(farmhouse);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                  ),
                );
              }),
            ),

            // ================= DETAILS (TAP TO OPEN) =================
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmhouseDetailsScreen(
                        id: widget.id ?? widget.name,
                        name: widget.name,
                        location: widget.location,
                        price: widget.price,
                        distance: widget.distance,
                        imageUrl: widget.imageUrl,
                        images: images,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.location,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${widget.price.toStringAsFixed(0)}/night',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB8E6A0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
