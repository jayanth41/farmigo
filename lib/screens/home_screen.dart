import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/location_controller.dart';
import '../data/farmhouses_data.dart';
import 'favorites_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'all_properties_screen.dart';
import '../navigation/app_routes.dart';
import '../widgets/category_tabs.dart';
import '../widgets/offers_carousel.dart';
import '../widgets/app_drawer.dart';
import '../widgets/properties_grid.dart';
import 'owner_dashboard.dart';
import 'filters_screen.dart';
import 'package:provider/provider.dart';
import '../filters/filters_provider.dart';
import '../controllers/app_location_controller.dart';
import 'package:geolocator/geolocator.dart';
import '../models/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LocationController locationController = Get.put(LocationController());
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late FavoritesController favoritesController;
  Map<String, dynamic>? _profile;
  bool _isProfileLoading = true;
  bool _didPromptForProfile = false;
  FiltersProvider? _filtersProvider;

  // Async location fetch state to avoid calling location APIs in build()
  Future<String?>? _locationFuture;
  bool _isFetchingLocation = false;

  // Location & Category selectors
 final String _selectedState = 'Telangana';
  String _selectedCategory = 'All';

  // Advanced filter state (shared with filters screen)
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _maxDistance = 100;
  bool _luxuryOnly = false;
  double _minRating = 0;
  final Map<String, bool> _amenities = {
    'Pool': false,
    'WiFi': false,
    'Kitchen': false,
    'Breakfast': false,
  };
  final Map<String, bool> _propertyTypes = {
    'Farmhouse': false,
    'Villa': false,
    'Hotel': false,
    'Apartment': false,
    'Cottage': false,
    'Homestay': false,
  };
  String _sortOption = 'Relevance';

  // Filtered list for search results
  List<Map<String, dynamic>> _filteredFarmhouses = [];

  // Reference to farmhouses data (defined in data file)
  static const List<Map<String, dynamic>> farmhouses = farmhousesData;

  @override
  void initState() {
    super.initState();
    _filteredFarmhouses = List.from(farmhouses);
    _searchController.addListener(_onSearchChanged);
    
    // Initialize FavoritesController
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    favoritesController = Get.find<FavoritesController>();
    
    // Initialize LocationController
    if (!Get.isRegistered<LocationController>()) {
      Get.put(LocationController());
    }
    locationController = Get.find<LocationController>();
    
    // Load Supabase-backed user profile (if authenticated)
    loadProfile();

    // Subscribe to global filters provider updates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final provider = Provider.of<FiltersProvider>(context, listen: false);
        _filtersProvider = provider;
        provider.addListener(_onGlobalFiltersChanged);
      } catch (_) {
        // Provider might not be available in some contexts; ignore.
      }
    });
  }

  Future<void> loadProfile() async {
    setState(() => _isProfileLoading = true);
    debugPrint('[HomeScreen] loadProfile: fetching profile...');
    final data = await UserService().fetchUserProfile();
    debugPrint('[HomeScreen] loadProfile: fetch returned: $data');
    if (!mounted) return;
    setState(() {
      _profile = data;
      _isProfileLoading = false;
    });

    // If user is authenticated but no profile exists, prompt them once
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser != null &&
        (_profile == null || _profile!['profile_completed'] == false) &&
        !_didPromptForProfile) {

      _didPromptForProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfilePage(profile: {})),
        );
        await loadProfile();
      });
    }
  }

  void _onDrawerItemSelected(String label) async {
    Navigator.of(context).pop();

    if (label.toLowerCase() == 'logout') {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (!mounted) return;
      try {
        Get.offAllNamed('/login');
      } catch (_) {
        try {
          Navigator.of(context).pushReplacementNamed('/login');
        } catch (_) {}
      }
      return;
    }

    if (label == AppRoutes.labelProfile || label == 'Profile') {
      if (_profile == null) return;
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfilePage(profile: _profile!),
        ),
      );
      await loadProfile();
      return;
    }

    final route = AppRoutes.labelToRoute[label];
    if (route == null || route.isEmpty) return;
    try {
      Get.toNamed(route);
    } catch (_) {
      try {
        Navigator.of(context).pushNamed(route);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    try {
      _filtersProvider?.removeListener(_onGlobalFiltersChanged);
    } catch (_) {}
    super.dispose();
  }

  Category _currentCategory() {
                        final s = _selectedCategory.toLowerCase();
                          if (s.contains('farm')) return Category.farmhouse;
                          if (s.contains('villa')) return Category.villa;
                          if (s.contains('hotel')) return Category.hotel;
                          if (s.contains('flight') || s.contains('flights')) return Category.flights;
                          if (s.contains('car')) return Category.car;
                          if (s.contains('hour')) return Category.hourly;
                          return Category.all;
  }

  void _onGlobalFiltersChanged() {
    final provider = _filtersProvider;
    if (provider == null) return;
    final cat = _currentCategory();
    final raw = provider.getRaw(cat);
    if (raw == null) return;

    setState(() {
      // Merge known keys into local filter state if present
      if (raw.containsKey('priceRange') && raw['priceRange'] is RangeValues) {
        _priceRange = raw['priceRange'] as RangeValues;
      }
      if (raw.containsKey('maxDistance') && raw['maxDistance'] is double) {
        _maxDistance = raw['maxDistance'] as double;
      }
      if (raw.containsKey('luxuryOnly') && raw['luxuryOnly'] is bool) {
        _luxuryOnly = raw['luxuryOnly'] as bool;
      }
      if (raw.containsKey('minRating') && raw['minRating'] is double) {
        _minRating = raw['minRating'] as double;
      }
      if (raw.containsKey('amenities') && raw['amenities'] is Map) {
        try {
          _amenities.addAll(Map<String, bool>.from(raw['amenities']));
        } catch (_) {}
      }
      if (raw.containsKey('propertyTypes') && raw['propertyTypes'] is Map) {
        try {
          _propertyTypes.addAll(Map<String, bool>.from(raw['propertyTypes']));
        } catch (_) {}
      }
      if (raw.containsKey('sortOption') && raw['sortOption'] is String) {
        _sortOption = raw['sortOption'] as String;
      }
    });

    // Re-apply filters to update UI
    _applyFilters();
  }

  void _onSearchChanged() => _applyFilters();

  // Fetch location asynchronously once (cached) and avoid calling Geolocator in build()
  Future<String?> _fetchLocationOnce() async {
    if (_locationFuture != null) return _locationFuture!;
    _locationFuture = () async {
      try {
        // Use the GetX LocationController to request/check permissions safely
        await locationController.checkLocationStatus();
        if (!locationController.isLocationEnabled.value) {
          await locationController.requestLocationPermission();
        }

        if (!locationController.isLocationEnabled.value) {
          return 'Location disabled';
        }

        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best).timeout(const Duration(seconds: 10));
        return '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      } catch (_) {
        return null;
      }
    }();

    return _locationFuture!;
  }

  // Show bottom sheet that runs _fetchLocationOnce and allows manual edit/save
  void _showLocationSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (bc) {
        final TextEditingController ctl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(bc).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<String?>(
              future: _fetchLocationOnce(),
              builder: (context, snap) {
                final loading = snap.connectionState == ConnectionState.waiting;
                final detected = snap.data;
                if (detected != null && detected.isNotEmpty) ctl.text = detected;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (loading) const Text('Fetching location...')
                    else if (detected == 'Location disabled') const Text('Location disabled')
                    else if (detected == null) const Text('Could not detect location')
                    else const SizedBox.shrink(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter location name or coordinates',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.of(bc).pop(), child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Persist manual override to AppLocationController if available
                            try {
                              final locCtrl = Provider.of<AppLocationController>(ctx, listen: false);
                              locCtrl.setLocationName(ctl.text.trim());
                            } catch (_) {}
                            Navigator.of(bc).pop();
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Location saved')));
                          },
                          child: const Text('Save'),
                        )
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final selectedState = _selectedState.toLowerCase();
    final selectedCategory = _selectedCategory.toLowerCase();

    setState(() {
      _filteredFarmhouses = farmhouses.where((farm) {
        final name = (farm['name'] as String).toLowerCase();
        final location = (farm['location'] as String).toLowerCase();
        final price = (farm['price'] as double?) ?? 0.0;
        final distance =
            double.tryParse((farm['distance'] as String).split(' ').first) ?? 0;

        bool matchesSearch = name.contains(query) || location.contains(query);

        if (!(price >= _priceRange.start && price <= _priceRange.end)) {
          return false;
        }
        if (distance > _maxDistance) return false;
        if (_luxuryOnly && price < 3500) return false;
        
        final rating = (farm['rating'] is double) ? (farm['rating'] as double) : 0.0;
        if (rating < _minRating) return false;

        final farmAmenities = (farm['amenities'] as List?)?.cast<String>() ?? <String>[];
        for (final entry in _amenities.entries) {
          if (entry.value && !farmAmenities.contains(entry.key)) {
            return false;
          }
        }

        // Check property type filtering
        final farmPropertyType = (farm['property_type'] as String?)?.toLowerCase() ?? '';
        bool propertyTypeMatches = true;
        bool anyPropertyTypeSelected = _propertyTypes.values.any((v) => v);
        
        if (anyPropertyTypeSelected) {
          propertyTypeMatches = _propertyTypes.entries.any((entry) =>
              entry.value && farmPropertyType.contains(entry.key.toLowerCase()));
        }
        if (!propertyTypeMatches) return false;

        final farmState = (farm['state'] as String?)?.toLowerCase() ?? '';
        final farmCategory = (farm['category'] as String?)?.toLowerCase() ?? '';

        if (selectedState.isNotEmpty &&
            selectedState != 'all' &&
            farmState != selectedState) {
          return false;
        }
        if (selectedCategory.isNotEmpty &&
            selectedCategory != 'all' &&
            farmCategory != selectedCategory) {
          return false;
        }

        return matchesSearch;
      }).toList();

      // Apply sorting
      switch (_sortOption) {
        case 'Price: Low to High':
          _filteredFarmhouses.sort((a, b) =>
              (a['price'] as double).compareTo(b['price'] as double));
          break;
        case 'Price: High to Low':
          _filteredFarmhouses.sort((a, b) =>
              (b['price'] as double).compareTo(a['price'] as double));
          break;
        case 'Distance':
          double dist(Map<String, dynamic> f) =>
              double.tryParse((f['distance'] as String).split(' ').first) ?? 0;
          _filteredFarmhouses.sort((a, b) => dist(a).compareTo(dist(b)));
          break;
        case 'Rating':
          double r(Map<String, dynamic> f) =>
              (f['rating'] is double) ? (f['rating'] as double) : 0.0;
          _filteredFarmhouses.sort((a, b) => r(b).compareTo(r(a)));
          break;
        case 'Relevance':
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        profile: _profile, 
        isProfileLoading: _isProfileLoading, 
        onItemSelected: _onDrawerItemSelected,
      ),
      backgroundColor: AppColors.bgSoft,
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _homePage();
      case 1:
        return const FavoritesScreen();
      case 2:
        return const BookingsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _homePage();
    }
  }

  Widget _homePage() {
    return SafeArea(
      child: Column(
        children: [
          // ---------- HEADER ----------
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F8F0), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: AppColors.primary),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // App logo
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'F',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Farmigo",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    // Title area - kept compact. Location label placed below this row.
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.primary),
                      onPressed: () {
                        final cat = () {
                          final s = _selectedCategory.toLowerCase();
                          if (s.contains('farm')) return Category.farmhouse;
                          if (s.contains('villa')) return Category.villa;
                          if (s.contains('hotel')) return Category.hotel;
                          if (s.contains('flight') || s.contains('flights')) return Category.flights;
                          if (s.contains('car')) return Category.car;
                          if (s.contains('hour')) return Category.hourly;
                          return Category.all;
                        }();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FiltersScreen(
                              category: cat,
                              onFiltersApplied: (filters) {
                                setState(() {
                                  _priceRange = filters['priceRange'] ?? _priceRange;
                                  _maxDistance = filters['maxDistance'] ?? _maxDistance;
                                  _luxuryOnly = filters['luxuryOnly'] ?? _luxuryOnly;
                                  _minRating = filters['minRating'] ?? _minRating;
                                  _amenities.addAll(filters['amenities'] ?? {});
                                  _propertyTypes.addAll(filters['propertyTypes'] ?? {});
                                  _sortOption = filters['sortOption'] ?? _sortOption;

                                  // map back some category-specific values if present
                                  if (cat == Category.farmhouse || cat == Category.villa) {
                                    // optional: read guests/location
                                  }
                                });
                                _applyFilters();
                              },
                              initialFilters: {
                                'priceRange': _priceRange,
                                'maxDistance': _maxDistance,
                                'luxuryOnly': _luxuryOnly,
                                'minRating': _minRating,
                                'amenities': _amenities,
                                'propertyTypes': _propertyTypes,
                                'sortOption': _sortOption,
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Small clickable current location placed under title, left aligned
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _showLocationSheet(context),
                      child: Text(
                        '📍 Current location',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ),
                  ),
                ),

                // SEARCH BAR (theme-aware)
                Builder(builder: (ctx) {
                  final cs = Theme.of(ctx).colorScheme;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      cursorColor: cs.primary,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: "Search farmhouses, villas...",
                        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: cs.onSurface.withOpacity(0.8)),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ---------- BODY ----------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const SizedBox(height: 16),
                // GREETING
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Color.fromARGB(255, 63, 62, 62)),
                      children: [
                        TextSpan(
                          text: "Hello 👋\n",
                          style: TextStyle(fontSize: 16),
                        ),
                        TextSpan(
                          text: "Where would you like to go?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // CATEGORIES
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Categories",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8.5),
                CategoryGrid(
                  selectedCategory: _selectedCategory,
                  onTap: (c) {
                    setState(() {
                      _selectedCategory = c;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 20),
                // OFFERS
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Best Offers",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                OffersCarousel(
                  offers: const [
                    OfferItem(
                      title: 'Weekend Deals',
                      subtitle: 'Up to 40% off',
                      icon: Icons.local_fire_department,
                      color: Color.fromARGB(255, 62, 179, 132),
                    ),
                    OfferItem(
                      title: 'Early Bird',
                      subtitle: 'Save 15%',
                      icon: Icons.percent,
                      color: Color.fromARGB(255, 108, 162, 207),
                    ),
                    OfferItem(
                      title: 'First Booking',
                      subtitle: '20% off',
                      icon: Icons.star_border,
                      color: Color.fromARGB(255, 58, 196, 67),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // FEATURED
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Featured Properties",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllPropertiesScreen(
                                properties: _filteredFarmhouses,
                              ),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View all'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                PropertiesGrid(properties: _filteredFarmhouses),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile['name'] ?? '');
    _phoneController = TextEditingController(text: widget.profile['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final profileHasId = widget.profile.containsKey('id') && 
        (widget.profile['id'] != null && 
         widget.profile['id'].toString().isNotEmpty);

    bool success = false;
    if (profileHasId) {
      success = await UserService().updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } else {
      try {
        await UserService().createUserIfNotExists(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        success = true;
      } catch (_) {
        success = false;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController, 
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController, 
              decoration: const InputDecoration(labelText: 'Phone'), 
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save, 
              child: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) 
                : const Text('Save'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerDashboard(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Owner Dashboard"),
            ),
          ],
        ),
      ),
    );
  }
}