# Favorites System - Usage Examples

## Quick Reference Guide

### Initialize FavoritesController

```dart
// Automatically done in HomeScreen.initState()
if (!Get.isRegistered<FavoritesController>()) {
  Get.put(FavoritesController());
}
favoritesController = Get.find<FavoritesController>();
```

---

## Common Operations

### 1. Add to Favorites

```dart
final farmhouse = FarmhouseModel(
  id: 'farmhouse_1',
  name: 'The Night Garden Stay',
  location: 'Anajpur, Hyderabad',
  price: 10000.0,
  distance: '15 km away',
  imageUrl: 'https://example.com/image.jpg',
);

final controller = Get.find<FavoritesController>();
await controller.addFavorite(farmhouse);
```

### 2. Remove from Favorites

```dart
final controller = Get.find<FavoritesController>();
await controller.removeFavorite('farmhouse_1');
```

### 3. Toggle Favorite

```dart
final controller = Get.find<FavoritesController>();
await controller.toggleFavorite(farmhouse);
// Adds if not favorited, removes if already favorited
```

### 4. Check if Favorited

```dart
final controller = Get.find<FavoritesController>();
bool isFavorited = controller.isFavorited('farmhouse_1');

if (isFavorited) {
  print('This farmhouse is in favorites');
} else {
  print('This farmhouse is not favorited');
}
```

### 5. Get Favorite Count

```dart
final controller = Get.find<FavoritesController>();
int count = controller.getFavoriteCount();
print('Total favorites: $count');
```

### 6. Get All Favorites

```dart
final controller = Get.find<FavoritesController>();
List<FarmhouseModel> allFavorites = controller.favorites;

for (var farmhouse in allFavorites) {
  print('${farmhouse.name} - ₹${farmhouse.price}');
}
```

### 7. Clear All Favorites

```dart
final controller = Get.find<FavoritesController>();
await controller.clearAllFavorites();
```

---

## Reactive UI Examples

### Display Favorite Count with Real-time Updates

```dart
Obx(
  () => Text(
    'Favorites: ${controller.getFavoriteCount()}',
  ),
)
```

### Reactive Heart Icon

```dart
Obx(
  () => Icon(
    controller.isFavorited('farmhouse_1') 
      ? Icons.favorite 
      : Icons.favorite_border,
    color: controller.isFavorited('farmhouse_1') 
      ? Colors.red 
      : Colors.grey,
  ),
)
```

### List All Favorites with Reactive Updates

```dart
Obx(
  () => ListView.builder(
    itemCount: controller.favorites.length,
    itemBuilder: (context, index) {
      final farmhouse = controller.favorites[index];
      return ListTile(
        title: Text(farmhouse.name),
        subtitle: Text(farmhouse.location),
      );
    },
  ),
)
```

### Conditional UI Based on Favorite Status

```dart
Obx(
  () {
    if (controller.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet!'),
      );
    }
    
    return ListView.builder(
      itemCount: controller.favorites.length,
      itemBuilder: (context, index) {
        return FarmhouseCard(
          farmhouse: controller.favorites[index],
        );
      },
    );
  },
)
```

---

## Navigation Examples

### Navigate to Favorites Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const FavoritesScreen(),
  ),
);

// Or using GetX
Get.to(() => const FavoritesScreen());
```

### Navigate to Details Screen from Favorites

```dart
final farmhouse = controller.favorites[index];
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
```

---

## Common Patterns

### Pattern 1: Heart Icon Button with Feedback

```dart
Obx(
  () => GestureDetector(
    onTap: () {
      controller.toggleFavorite(farmhouse);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.isFavorited(farmhouse.id)
              ? '❤️ Added to favorites'
              : '💔 Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    },
    child: Icon(
      controller.isFavorited(farmhouse.id)
        ? Icons.favorite
        : Icons.favorite_border,
      color: controller.isFavorited(farmhouse.id)
        ? Colors.red
        : Colors.grey,
    ),
  ),
)
```

### Pattern 2: Favorite Badge in AppBar

```dart
Obx(
  () => Stack(
    children: [
      IconButton(
        icon: const Icon(Icons.favorite),
        onPressed: () => Get.to(() => const FavoritesScreen()),
      ),
      if (controller.getFavoriteCount() > 0)
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${controller.getFavoriteCount()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
    ],
  ),
)
```

### Pattern 3: Loading Favorites on App Start

```dart
@override
void initState() {
  super.initState();
  
  // Initialize controller
  if (!Get.isRegistered<FavoritesController>()) {
    Get.put(FavoritesController());
  }
  
  // Favorites are automatically loaded by FavoritesController.onInit()
  controller = Get.find<FavoritesController>();
}
```

### Pattern 4: Remove from Favorites Button

```dart
ElevatedButton(
  onPressed: () async {
    await controller.removeFavorite(farmhouse.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites')),
    );
  },
  child: const Text('Remove from Favorites'),
)
```

---

## Integration with Backend

### Save to Server After Adding Favorite

```dart
Future<void> addFavoriteWithServer(FarmhouseModel farmhouse) async {
  // Add locally
  await controller.addFavorite(farmhouse);
  
  // Sync with server
  try {
    await firebaseService.addFavorite(farmhouse.id);
  } catch (e) {
    // Handle server error - optionally remove from local
    await controller.removeFavorite(farmhouse.id);
    print('Error syncing with server: $e');
  }
}
```

### Fetch Favorites from Server

```dart
@override
void initState() {
  super.initState();
  controller = Get.find<FavoritesController>();
  
  // Fetch from server and merge with local
  _loadServerFavorites();
}

Future<void> _loadServerFavorites() async {
  try {
    final serverFavorites = await firebaseService.getFavorites();
    
    for (var favorite in serverFavorites) {
      if (!controller.isFavorited(favorite.id)) {
        await controller.addFavorite(favorite);
      }
    }
  } catch (e) {
    print('Error loading server favorites: $e');
  }
}
```

---

## Error Handling

### Safe Toggle with Error Handling

```dart
Future<void> safToggleFavorite(FarmhouseModel farmhouse) async {
  try {
    await controller.toggleFavorite(farmhouse);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error updating favorites: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## Performance Tips

1. **Avoid rebuilding entire list:**
   ```dart
   // ❌ Bad - rebuilds entire list
   controller.favorites.refresh();
   
   // ✅ Good - only affected widgets rebuild
   // Automatic with Obx()
   ```

2. **Cache controller reference:**
   ```dart
   // ✅ Good - cache in initState
   late FavoritesController controller;
   
   @override
   void initState() {
    super.initState();
    controller = Get.find<FavoritesController>();
   }
   ```

3. **Use Obx selectively:**
   ```dart
   // ✅ Only wrap reactive parts
   Obx(() => Icon(...))
   
   // ❌ Avoid wrapping entire screen
   Obx(() => Scaffold(...))
   ```

---

## Testing Examples

```dart
// Test adding favorite
test('Add favorite farmhouse', () async {
  final farmhouse = FarmhouseModel(/* ... */);
  final controller = FavoritesController();
  
  await controller.addFavorite(farmhouse);
  
  expect(controller.isFavorited(farmhouse.id), true);
  expect(controller.getFavoriteCount(), 1);
});

// Test removing favorite
test('Remove favorite farmhouse', () async {
  final farmhouse = FarmhouseModel(/* ... */);
  final controller = FavoritesController();
  
  await controller.addFavorite(farmhouse);
  await controller.removeFavorite(farmhouse.id);
  
  expect(controller.isFavorited(farmhouse.id), false);
  expect(controller.getFavoriteCount(), 0);
});

// Test persistence
test('Favorites persist after reload', () async {
  final controller1 = FavoritesController();
  await controller1.addFavorite(farmhouse);
  
  // Simulate app restart
  final controller2 = FavoritesController();
  await controller2.loadFavorites();
  
  expect(controller2.isFavorited(farmhouse.id), true);
});
```

---

## Troubleshooting

### Issue: Heart icon not updating
**Solution:** Ensure the widget is wrapped with `Obx()` and controller is properly registered.

### Issue: Favorites lost after app restart
**Solution:** Verify SharedPreferences is initialized in `initState()` of FavoritesController.

### Issue: Multiple instances of controller
**Solution:** Use `Get.isRegistered()` before `Get.put()` to avoid duplicates.

### Issue: Badge not showing
**Solution:** Check `getFavoriteCount()` is greater than 0 and `Obx()` is properly wrapping the badge widget.

---

This guide covers all common use cases for the global favorites system!
