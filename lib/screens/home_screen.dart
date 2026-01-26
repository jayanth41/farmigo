import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/location_controller.dart';
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


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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
    final profileHasId = widget.profile.containsKey('id') && (widget.profile['id'] != null && widget.profile['id'].toString().isNotEmpty);

    bool success = false;
    if (profileHasId) {
      success = await UserService().updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } else {
      // Create a new profile row for the authenticated user.
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerDashboard(),
      ),
    );
  },
  child: const Text("Owner Dashboard"),
),

            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isSaving ? null : _save, child: _isSaving ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Save')),
          ],
        ),
      ),
    );
  }
}


 

class _HomeScreenState extends State<HomeScreen> {
  final LocationController locationController =
  Get.put(LocationController());
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late FavoritesController favoritesController;
  Map<String, dynamic>? _profile;
  bool _isProfileLoading = true;
  bool _didPromptForProfile = false;


  // Location & Category selectors
  final String _selectedState = 'Telangana';
  String _selectedCategory = 'All';
  final bool _showOffers = true;

  // Advanced filter state
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

  // (states list removed - unused after UI changes)

  // Dummy farmhouse data
  static const List<Map<String, dynamic>> farmhouses = [
    {
      'name': 'The Night Garden Stay',
      'location': 'Anajpur, Hyderabad',
      'state': 'Telangana',
      'category': 'Farmhouses',
      'price': 10000.0,
      'distance': '15 km away',
      'rating': 4.8,
      'reviews': 245,
      'amenities': ['Pool', 'WiFi', 'Kitchen', 'Breakfast'],
      'imageUrl':
          'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/view2.jpeg',
      'images': [
        'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/drone.jpeg',
        'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/wat.jpeg',
        'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/view2.jpeg',
        'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/projecter.jpeg',
        'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/ott.jpeg',
        'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/att.jpeg',
        'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/lawn.jpeg',
        'https://raw.githubusercontent.com/jayanth41/images/refs/heads/main/image.png',
      ],
      'discount': 15,
    },
    {
      'name': 'Organic Farm Retreat',
      'location': 'Tandur, Telangana',
      'state': 'Telangana',
      'category': 'Farmhouses',
      'price': 1800.0,
      'distance': '25 km away',
      'rating': 4.0,
      'reviews': 78,
      'amenities': ['Kitchen', 'Breakfast'],
      'imageUrl':
          'https://images.unsplash.com/photo-1549294413-26f195200c16?w=600&auto=format&fit=crop&q=60',
      'discount': 15,
    },
    {
      'name': 'Riverside Farmhouse',
      'location': 'Yadagirigutta, Telangana',
      'state': 'Telangana',
      'category': 'Farmhouses',
      'price': 2800.0,
      'distance': '35 km away',
      'rating': 3.9,
      'reviews': 42,
      'amenities': ['WiFi', 'Kitchen'],
      'imageUrl':
          'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'Heritage Farm Stay',
      'location': 'Vikarabad, Telangana',
      'state': 'Telangana',
      'category': 'Farmhouses',
      'price': 2200.0,
      'distance': '45 km away',
      'rating': 4.2,
      'reviews': 94,
      'amenities': ['Breakfast', 'Kitchen'],
      'imageUrl':
          'https://plus.unsplash.com/premium_photo-1661923725782-f73c990fbddf?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'Sunny Hills Villa',
      'location': 'Lonavala, Maharashtra',
      'state': 'Maharashtra',
      'category': 'Villas',
      'price': 15000.0,
      'distance': '120 km away',
      'rating': 4.7,
      'reviews': 312,
      'amenities': ['Pool', 'Garden', 'BBQ'],
      'imageUrl':
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'Beachside Villa Escape',
      'location': 'Goa',
      'state': 'Goa',
      'category': 'Villas',
      'price': 22000.0,
      'distance': '560 km away',
      'rating': 4.9,
      'reviews': 421,
      'amenities': ['Pool', 'Sea View', 'Private Chef'],
      'imageUrl':
          'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'Serene Hills Resort',
      'location': 'Hyderabad, Telangana',
      'state': 'Telangana',
      'category': 'Hotels',
      'price': 13500.0,
      'distance': '8 km away',
      'rating': 4.4,
      'reviews': 198,
      'amenities': ['WiFi', 'Breakfast'],
      'imageUrl':
          'https://images.unsplash.com/photo-1546623381-7a0f3b6f0b1b?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'City Center Hotel',
      'location': 'Secunderabad, Telangana',
      'state': 'Telangana',
      'category': 'Hotels',
      'price': 7200.0,
      'distance': '10 km away',
      'rating': 4.1,
      'reviews': 86,
      'amenities': ['WiFi', 'Gym'],
      'imageUrl':
          'https://images.unsplash.com/photo-1526772662000-3f88f10405ff?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'Quick Stay Rooms',
      'location': 'Hyderabad City Center',
      'state': 'Telangana',
      'category': 'Hourly Rentals',
      'price': 500.0,
      'distance': '5 km away',
      'rating': 4.3,
      'reviews': 67,
      'amenities': ['WiFi', 'AC'],
      'imageUrl':
          'https://images.unsplash.com/photo-1631049307038-da31500055b1?w=600&auto=format&fit=crop&q=60',
      'discount': 10,
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredFarmhouses = List.from(farmhouses);
    _searchController.addListener(_onSearchChanged);
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    if (!Get.isRegistered<LocationController>()) {
      Get.put(LocationController());
    }
    favoritesController = Get.find<FavoritesController>();
    // Load Supabase-backed user profile (if authenticated)
    loadProfile();
  }

  Future<void> loadProfile() async {
    // start loading
    setState(() => _isProfileLoading = true);
  debugPrint('[HomeScreen] loadProfile: fetching profile...');
    final data = await UserService().fetchUserProfile();
  debugPrint('[HomeScreen] loadProfile: fetch returned: $data');
    if (!mounted) return;
    setState(() {
      _profile = data;
      _isProfileLoading = false;
    });

    // If user is authenticated but no profile exists, prompt them once to
    // complete their profile by opening the EditProfilePage.
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser != null &&
    (_profile == null || _profile!['profile_completed'] == false) &&
    !_didPromptForProfile) {

      _didPromptForProfile = true;
      // Delay navigation until after current frame to avoid navigator errors.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditProfilePage(profile: {})),
        );
        // Refresh after potential profile creation.
        await loadProfile();
      });
    }
  }

  // Drawer item handler moved to a dedicated method to keep build() tidy.
  void _onDrawerItemSelected(String label) async {
    // Close the drawer first so navigation happens off-screen
    Navigator.of(context).pop();

    // Handle logout explicitly
    if (label.toLowerCase() == 'logout') {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (!mounted) return;
      // Send user to login screen (named route used in main.dart)
      try {
        Get.offAllNamed('/login');
      } catch (_) {
        try {
          Navigator.of(context).pushReplacementNamed('/login');
        } catch (_) {}
      }
      return;
    }

    // Open profile editor when Profile selected
    if (label == AppRoutes.labelProfile || label == 'Profile') {
      if (_profile == null) return;

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfilePage(profile: _profile!),
        ),
      );

      // refresh after edit
      await loadProfile();
      return;
    }

    // Map label to route if available
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

  // state selector removed (not used) to reduce analyzer noise

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _applyFilters();

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
        final rating =
            (farm['rating'] is double) ? (farm['rating'] as double) : 0.0;
        if (rating < _minRating) return false;

        final farmAmenities =
            (farm['amenities'] as List?)?.cast<String>() ?? <String>[];
        for (final entry in _amenities.entries) {
          if (entry.value && !farmAmenities.contains(entry.key)) {
            return false;
          }
        }

        final farmState = (farm['state'] as String?)?.toLowerCase() ?? '';
        final farmCategory =
            (farm['category'] as String?)?.toLowerCase() ?? '';

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
      drawer: AppDrawer(profile: _profile, isProfileLoading: _isProfileLoading, onItemSelected: _onDrawerItemSelected,),
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
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: 'Bookings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.tune_outlined), label: 'Filters'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) return _homePage();
    if (_selectedIndex == 1) return const FavoritesScreen();
    if (_selectedIndex == 2) return const BookingsScreen();
    if (_selectedIndex == 3) return _filtersPage();
    return const ProfileScreen();
  }

  Widget _homePage() {
  return SafeArea(
    child: Column(
      children: [
        // ---------- HEADER ----------
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
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

    // App logo fallback: simple rounded green badge with 'F'
    Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: const Center(
        child: Text(
          'F',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
    ),

    const SizedBox(width: 8),

    const Text(
      "Farmigo",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    ),

    const Spacer(),

    IconButton(
      icon: const Icon(Icons.tune, color: AppColors.primary),
      onPressed: () => setState(() => _selectedIndex = 3),
    ),
  ],
),


              const SizedBox(height: 12),

              // SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search farmhouses, villas...",
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ---------- BODY ----------
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SizedBox(height: 16),
Padding(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
  text: const TextSpan(
    style: TextStyle(color: AppColors.textMain),
    children: [
      TextSpan(text: "Hello 👋\n", style: TextStyle(fontSize: 14)),
      TextSpan(
        text: "Where would you like to go?",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ],
  ),
),

      SizedBox(height: 2),
      Text(
        "Where would you like to go?",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ],
  ),
),



              // CATEGORIES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  "Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  "Best Offers",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),

              OffersCarousel(
                offers: const [
                  OfferItem(
                      title: 'Weekend Deals',
                      subtitle: 'Up to 40% off',
                      icon: Icons.local_fire_department,
                      color: Color(0xFF6EE7B7)),
                  OfferItem(
                      title: 'Early Bird',
                      subtitle: 'Save 15%',
                      icon: Icons.percent,
                      color: Color(0xFF86C9FF)),
                  OfferItem(
                      title: 'First Booking',
                      subtitle: '20% off',
                      icon: Icons.star_border,
                      color: Color(0xFFAAF27A)),
                ],
              ),

              const SizedBox(height: 20),

              // FEATURED
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Featured Properties",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
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


  Widget _filtersPage() {
    final amenitiesKeys = _amenities.keys.toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // 1. Price range
            const Text('Price range'),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 10000,
              divisions: 100,
              labels: RangeLabels('₹${_priceRange.start.toInt()}',
                  '₹${_priceRange.end.toInt()}'),
              onChanged: (r) => setState(() => _priceRange = r),
            ),
            const SizedBox(height: 8),

            // 2. Minimum rating
            const Text('Minimum rating'),
            Slider(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 5,
              label: _minRating.toStringAsFixed(1),
              onChanged: (v) => setState(() => _minRating = v),
            ),
            const SizedBox(height: 8),

            // 3. Amenities
            const Text('Amenities'),
            Wrap(
              spacing: 8,
              children: List.generate(amenitiesKeys.length, (i) {
                final key = amenitiesKeys[i];
                return FilterChip(
                  label: Text(key),
                  selected: _amenities[key] ?? false,
                  onSelected: (v) => setState(() => _amenities[key] = v),
                );
              }),
            ),
            const SizedBox(height: 12),

            // 4. Property type
            const Text('Property type'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _propertyTypes.keys.map((k) {
                return FilterChip(
                  label: Text(k),
                  selected: _propertyTypes[k] ?? false,
                  onSelected: (v) => setState(() => _propertyTypes[k] = v),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Other optional filters
            const Text('Max distance (km)'),
            DropdownButton<String>(
              value: _sortOption,
              items: const [
                DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
                DropdownMenuItem(
                    value: 'Price: Low to High',
                    child: Text('Price: Low to High')),
                DropdownMenuItem(
                    value: 'Price: High to Low',
                    child: Text('Price: High to Low')),
                DropdownMenuItem(value: 'Distance', child: Text('Distance')),
                DropdownMenuItem(value: 'Rating', child: Text('Rating')),
              ],
              onChanged: (v) => setState(() => _sortOption = v ?? 'Relevance'),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      setState(() => _selectedIndex = 0);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: const Text('Apply'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _priceRange = const RangeValues(0, 10000);
                        _maxDistance = 100;
                        _luxuryOnly = false;
                        _minRating = 0;
                        _amenities.updateAll((key, value) => false);
                        _sortOption = 'Relevance';
                      });
                      _applyFilters();
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}