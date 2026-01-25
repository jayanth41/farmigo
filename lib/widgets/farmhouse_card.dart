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

  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  List<String> get _imageList {
    if (widget.images != null && widget.images!.isNotEmpty) {
      return widget.images!;
    }
    if (widget.image.isNotEmpty) {
      return [widget.image];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    favoritesController = Get.find<FavoritesController>();

    _startAutoSlide();
  }

  void _startAutoSlide() {
    if (_imageList.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      _currentIndex = (_currentIndex + 1) % _imageList.length;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFavorite() async {
    final farmhouse = FarmhouseModel(
      id: widget.name,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFav
              ? '${widget.name} removed from favorites'
              : '${widget.name} added to favorites',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        favoritesController.isFavorited(widget.name);

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
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE SLIDER
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _imageList.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (_, index) {
                        return ImageWithFallback(
                          imageUrl: _imageList[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),

                /// DOT INDICATOR
                if (_imageList.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _imageList.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == i ? 8 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == i
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (widget.discount != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _discountBadge("${widget.discount}% OFF"),
                  ),

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
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.15),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: isFavorite
                            ? Colors.red
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            /// CONTENT (unchanged)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.reviews} reviews',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
