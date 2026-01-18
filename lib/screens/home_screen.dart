import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../controllers/favorites_controller.dart';
import 'favorites_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'all_properties_screen.dart';
import '../widgets/category_tabs.dart';
import '../widgets/offers_banner.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/properties_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late FavoritesController favoritesController;

  // Location & Category selectors
  String _selectedState = 'Telangana';
  String _selectedCategory = 'Farmhouses';

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
  String _sortOption = 'Relevance';

  // Filtered list for search results
  List<Map<String, dynamic>> _filteredFarmhouses = [];

  // All Indian States
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

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
      'imageUrl': 'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=600&auto=format&fit=crop&q=60',
      'images': [
        'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=600&auto=format&fit=crop&q=60',
        'https://images.unsplash.com/photo-1549294413-26f195200c16?w=600&auto=format&fit=crop&q=60',
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
      'imageUrl': 'https://images.unsplash.com/photo-1549294413-26f195200c16?w=600&auto=format&fit=crop&q=60',
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
      'imageUrl': 'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=600&auto=format&fit=crop&q=60',
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
      'imageUrl': 'https://plus.unsplash.com/premium_photo-1661923725782-f73c990fbddf?w=600&auto=format&fit=crop&q=60',
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
      'imageUrl': 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=600&auto=format&fit=crop&q=60',
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
      'imageUrl': 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=600&auto=format&fit=crop&q=60',
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
      'imageUrl': 'https://images.unsplash.com/photo-1546623381-7a0f3b6f0b1b?w=600&auto=format&fit=crop&q=60',
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
      'imageUrl': 'https://images.unsplash.com/photo-1526772662000-3f88f10405ff?w=600&auto=format&fit=crop&q=60',
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
    favoritesController = Get.find<FavoritesController>();
  }

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
        final distance = double.tryParse((farm['distance'] as String).split(' ').first) ?? 0;

        bool matchesSearch = name.contains(query) || location.contains(query);

        if (!(price >= _priceRange.start && price <= _priceRange.end)) return false;
        if (distance > _maxDistance) return false;
        if (_luxuryOnly && price < 3500) return false;
        final rating = (farm['rating'] is double) ? (farm['rating'] as double) : 0.0;
        if (rating < _minRating) return false;

        final farmAmenities = (farm['amenities'] as List?)?.cast<String>() ?? <String>[];
        for (final entry in _amenities.entries) {
          if (entry.value && !farmAmenities.contains(entry.key)) return false;
        }

        final farmState = (farm['state'] as String?)?.toLowerCase() ?? '';
        final farmCategory = (farm['category'] as String?)?.toLowerCase() ?? '';

        if (selectedState.isNotEmpty && selectedState != 'all' && farmState != selectedState) return false;
        if (selectedCategory.isNotEmpty && selectedCategory != 'all' && farmCategory != selectedCategory) return false;

        return matchesSearch;
      }).toList();

      switch (_sortOption) {
        case 'Price: Low to High':
          _filteredFarmhouses.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
          break;
        case 'Price: High to Low':
          _filteredFarmhouses.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
          break;
        case 'Distance':
          double dist(Map<String, dynamic> f) => double.tryParse((f['distance'] as String).split(' ').first) ?? 0;
          _filteredFarmhouses.sort((a, b) => dist(a).compareTo(dist(b)));
          break;
        case 'Rating':
          double r(Map<String, dynamic> f) => (f['rating'] is double) ? (f['rating'] as double) : 0.0;
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
      drawer: const AppDrawer(),
      backgroundColor: AppColors.bgSoft,
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
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
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), label: 'Filters'),
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
    return Stack(
      children: [
        Column(
          children: [
            // HEADER WITH LOGO, MENU, AND LOCATION DROPDOWN
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2FBF2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Top bar with menu, logo, title, and location dropdown
                  Row(
                    children: [
                      // Hamburger menu icon
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: AppColors.primary, size: 28),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Logo image or fallback
                      Image.asset(
                        'assets/images/logo_f.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, st) => Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text('F',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Brand name
                      const Text(
                        'FARMIGO',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      // Location dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedState,
                          underline: Container(),
                          items: indianStates.map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(
                                state,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedState = value;
                                _applyFilters();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // MAIN CONTENT
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _applyFilters();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 180),
                  children: [
                    // Category tabs
                    CategoryTabs(
                      activeCategory: _selectedCategory,
                      onCategoryChange: (c) => setState(() {
                        _selectedCategory = c;
                        _applyFilters();
                      }),
                    ),

                    // Offers banner
                    const OffersBanner(),
                    const SizedBox(height: 16),

                    // Properties header with View all button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Featured Properties',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllPropertiesScreen(
                                      properties: _filteredFarmhouses),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 66, 202, 85)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('View all'),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Properties grid
                    PropertiesGrid(properties: _filteredFarmhouses),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
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
            const Text('Max distance (km)'),
            Slider(
              value: _maxDistance,
              min: 1,
              max: 200,
              divisions: 199,
              label: '${_maxDistance.toInt()} km',
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Luxury only'),
                Switch(
                  value: _luxuryOnly,
                  onChanged: (v) => setState(() => _luxuryOnly = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            const Text('Sort by'),
            DropdownButton<String>(
              value: _sortOption,
              items: const [
                DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
                DropdownMenuItem(
                    value: 'Price: Low to High', child: Text('Price: Low to High')),
                DropdownMenuItem(
                    value: 'Price: High to Low', child: Text('Price: High to Low')),
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