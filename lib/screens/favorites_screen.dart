import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/favorites_controller.dart';
// theme colors used via Theme.of(context)
import 'property_details_screen.dart';
import '../widgets/image_with_fallback.dart';
import '../navigation/app_routes.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late FavoritesController favoritesController;

  String _sortType = 'recent';

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
      // Custom curved header similar to Help & Support, no back arrow
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 41, 70, 92),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'My Favorites',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your saved dream stays...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                  ),
                  const SizedBox(height: 16),
                      Text(
                        'No Favorites Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                  const SizedBox(height: 8),
                      Text(
                        'Add Properties to your favorites to see them here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.offAllNamed(AppRoutes.home);
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved: ${favoritesController.favorites.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortType,
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        items: const [
                          DropdownMenuItem(value: 'recent', child: Text('Recently Added')),
                          DropdownMenuItem(value: 'low', child: Text('Price Low to High')),
                          DropdownMenuItem(value: 'high', child: Text('Price High to Low')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortType = value ?? 'recent';
                          });
                        },
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      )
                    : (() {
                        final sortedFavorites = [...favoritesController.favorites];
                        if (_sortType == 'low') {
                          sortedFavorites.sort((a, b) => a.price.compareTo(b.price));
                        } else if (_sortType == 'high') {
                          sortedFavorites.sort((a, b) => b.price.compareTo(a.price));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedFavorites.length,
                          itemBuilder: (context, index) {
                            final farmhouse = sortedFavorites[index];
                            return Dismissible(
                              key: Key(farmhouse.id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                final removedItem = farmhouse;
                                final removedIndex = index;

                                favoritesController.removeFavorite(farmhouse.id);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${farmhouse.name} removed'),
                                    duration: const Duration(seconds: 3),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        favoritesController.favorites.insert(removedIndex, removedItem);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: FavoriteCard(
                                farmhouse: farmhouse,
                                onRemove: () {
                                  favoritesController.removeFavorite(farmhouse.id);
                                },
                              ),
                            );
                          },
                        );
                      })(),
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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
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
                // Property Type Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:Text(
                        'Farmhouse', // default type
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ),
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
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
                  // Rating row
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        farmhouse.rating?.toStringAsFixed(1) ?? '4.5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${farmhouse.reviewCount ?? 0} reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
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
                            builder: (context) => PropertyDetailsScreen(
                              propertyId: farmhouse.id,
                              currentUserId: FirebaseAuth.instance.currentUser?.uid,
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