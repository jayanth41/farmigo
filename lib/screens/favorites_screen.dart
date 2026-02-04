import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../controllers/favorites_controller.dart';
// theme colors used via Theme.of(context)
import 'farmhouse_details_screen.dart';
import '../widgets/image_with_fallback.dart';
import '../navigation/app_routes.dart';
import 'all_properties_screen.dart';
import '../data/farmhouses_data.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late FavoritesController favoritesController;

  @override
  void initState() {
    super.initState();
    favoritesController = Get.find<FavoritesController>();
  }

  // Using the controller's full favorites list directly (no category filters)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Secondary screen: remove drawer and provide a back button in AppBar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          Obx(
            () => favoritesController.favorites.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: 'Clear all favorites',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Clear Favorites'),
                            content: const Text(
                              'Are you sure you want to remove all favorites?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  favoritesController.clearAllFavorites();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All favorites cleared'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Clear',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(
        () {
          if (favoritesController.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.35),
                  ),
                  const SizedBox(height: 16),
                      Text(
                        'No Favorites Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.8),
                        ),
                      ),
                  const SizedBox(height: 8),
                      Text(
                        'Add farmhouses to your favorites to see them here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.65),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to AllPropertiesScreen showing all properties
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllPropertiesScreen(properties: farmhousesData),
                          ),
                        );
                      } catch (_) {
                        // Fallback to named route if needed
                        try {
                          Get.toNamed(AppRoutes.farmhouses);
                        } catch (_) {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.farmhouses);
                        }
                      }
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // (Category filters removed - showing all favorites)

              // SAVED COUNT
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Saved: ${favoritesController.favorites.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // FAVORITES LIST
              Expanded(
                child: favoritesController.favorites.isEmpty
                    ? Center(
                        child: Text(
                          'No favorites in this category',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: favoritesController.favorites.length,
                        itemBuilder: (context, index) {
                          final farmhouse = favoritesController.favorites[index];
                          return FavoriteCard(
                            farmhouse: farmhouse,
                            onRemove: () {
                              favoritesController.removeFavorite(farmhouse.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${farmhouse.name} removed from favorites'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // category filters removed; no helper needed
}

class FavoriteCard extends StatelessWidget {
  final dynamic farmhouse;
  final VoidCallback onRemove;

  const FavoriteCard({
    super.key,
    required this.farmhouse,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.06),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Image
            Stack(
              children: [
                ImageWithFallback(
                  imageUrl: farmhouse.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove from Favorites?'),
                          content: Text(
                              'Are you sure you want to remove ${farmhouse.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                onRemove();
                              },
                              child: const Text('Remove',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    farmhouse.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          farmhouse.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Distance and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        farmhouse.distance,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.65),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${farmhouse.price.toStringAsFixed(0)}/night',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // View Details Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FarmhouseDetailsScreen(
                              name: farmhouse.name,
                              location: farmhouse.location,
                              price: farmhouse.price,
                              distance: farmhouse.distance,
                              imageUrl: farmhouse.imageUrl,
                              id: farmhouse.id,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
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