import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
// FarmhouseCard is used inside PropertiesGrid; HomeScreen no longer imports it directly.
import '../controllers/favorites_controller.dart';
import 'favorites_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import '../widgets/search_card.dart';
import '../widgets/state_selector.dart';
import '../widgets/category_tabs.dart';
import '../widgets/search_section.dart';
import '../widgets/offers_banner.dart';
import '../widgets/properties_grid.dart';
// promo_box removed — SearchCard is used instead

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late FavoritesController favoritesController;

  // Quick chip filter
  String _selectedFilter = 'All';

  // Location & Category selectors
  String _selectedState = 'Telangana';
  String _selectedCategory = 'Farmhouses';

  // Advanced filter state
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _maxDistance = 100; // in km
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

  // Dummy farmhouse data (enriched with rating & amenities)
  static const List<Map<String, dynamic>> farmhouses = [
    {
      'name': 'The Night Garden Stay',
      'location': 'Anajpur, Hyderabad',
      'state': 'Telangana',
      'category': 'Farmhouses',
      'price': 10000.0,
      'distance': '15 km away',
      'rating': 4.8,
      'amenities': ['Pool', 'WiFi', 'Kitchen', 'Breakfast'],
  'imageUrl': 'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=600&auto=format&fit=crop&q=60',
      'images': [
  'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=600&auto=format&fit=crop&q=60',
  'https://images.unsplash.com/photo-1549294413-26f195200c16?w=600&auto=format&fit=crop&q=60',
      ],
    },
    {
      'name': 'Serene Hills Resort',
      'location': 'Hyderabad, Telangana',
      'state': 'Telangana',
      'category': 'Hotels',
      'price': 13500.0,
      'distance': '8 km away',
      'rating': 4.4,
      'amenities': ['WiFi', 'Breakfast'],
  'imageUrl': 'https://images.unsplash.com/photo-1561501900-3701fa6a0864?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'Organic Farm Retreat',
      'location': 'Tandur, Telangana',
      'state': 'Telangana',
      'category': 'Farmhouses',
      'price': 1800.0,
      'distance': '25 km away',
      'rating': 4.0,
      'amenities': ['Kitchen', 'Breakfast'],
  'imageUrl': 'https://images.unsplash.com/photo-1549294413-26f195200c16?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'Riverside Farmhouse',
      'location': 'Yadagirigutta, Telangana',
      'state': 'Telangana',
      'category': 'Farmhouses',
      'price': 2800.0,
      'distance': '35 km away',
      'rating': 3.9,
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
      'amenities': ['Breakfast', 'Kitchen'],
      'imageUrl':
          'https://plus.unsplash.com/premium_photo-1661923725782-f73c990fbddf?w=600&auto=format&fit=crop&q=60',
    },
    {
      'name': 'Premium Agri Resort',
      'location': 'Narayankhed, Telangana',
      'state': 'Telangana',
      'category': 'Resorts',
      'price': 14000.0,
      'distance': '60 km away',
      'rating': 4.6,
      'amenities': ['Pool', 'WiFi'],
      'imageUrl':
          'https://images.unsplash.com/photo-1549294413-26f195200c16?w=600&auto=format&fit=crop&q=60',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredFarmhouses = List.from(farmhouses);
    _searchController.addListener(_onSearchChanged);
    // Initialize or get existing FavoritesController
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // keep placeholder for possible future logout wiring
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

        // SEARCH MATCH
        bool matchesSearch = name.contains(query) || location.contains(query);

        // Quick chip filters
        bool matchesFilter;
        switch (_selectedFilter) {
          case 'Under ₹2000':
            matchesFilter = price <= 2000;
            break;
          case 'Within 20km':
            matchesFilter = distance <= 20;
            break;
          case 'Luxury':
            matchesFilter = price >= 3500;
            break;
          case 'All':
          default:
            matchesFilter = true;
        }

        // Advanced filters (further restrict)
        if (!(price >= _priceRange.start && price <= _priceRange.end)) return false;
        if (distance > _maxDistance) return false;
        if (_luxuryOnly && price < 3500) return false;
        final rating = (farm['rating'] is double) ? (farm['rating'] as double) : 0.0;
        if (rating < _minRating) return false;

        final farmAmenities = (farm['amenities'] as List?)?.cast<String>() ?? <String>[];
        for (final entry in _amenities.entries) {
          if (entry.value && !farmAmenities.contains(entry.key)) return false;
        }

        // STATE & CATEGORY filtering
        final farmState = (farm['state'] as String?)?.toLowerCase() ?? '';
        final farmCategory = (farm['category'] as String?)?.toLowerCase() ?? '';

        if (selectedState.isNotEmpty && selectedState != 'all' && farmState != selectedState) return false;
        if (selectedCategory.isNotEmpty && selectedCategory != 'all' && farmCategory != selectedCategory) return false;

        return matchesSearch && matchesFilter;
      }).toList();

      // Sorting
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

  // (removed older homePage) the stacked version below is used instead

  // New stacked home page with floating search card at the bottom
  Widget _homePage() {
    return Stack(
      children: [
        Column(
          children: [
            // Polished header (very very light green background)
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
              padding: const EdgeInsets.only(
                top: 28,
                left: 16,
                right: 16,
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: title + avatar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // logo before Farmigo
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.asset(
                                    'assets/images/logo_f.png',
                                    width: 36,
                                    height: 36,
                                    errorBuilder: (ctx, err, st) => Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text('f', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'FARMIGO',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // location beside title
                                StateSelector(
                                  selectedState: _selectedState,
                                  onSelect: (s) => setState(() {
                                    _selectedState = s;
                                    _applyFilters();
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Find your perfect ${_selectedCategory.toLowerCase()} retreat',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      // simple profile avatar (visible with green background)
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // The composed Home body (mirrors React composition)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _applyFilters();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 180),
                  children: [
                    CategoryTabs(
                      activeCategory: _selectedCategory,
                      onCategoryChange: (c) => setState(() {
                        _selectedCategory = c;
                        _applyFilters();
                      }),
                    ),

                    // Docked search card placed inline so it scrolls with the list
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: SearchCard(
                        onFind: (criteria) {
                          setState(() {
                            final loc = (criteria['location'] as String?) ?? '';
                            if (loc.isNotEmpty) _searchController.text = loc;
                            final cat = (criteria['category'] as String?) ?? '';
                            if (cat.isNotEmpty) _selectedCategory = cat;
                          });
                          _applyFilters();
                        },
                      ),
                    ),

                    SearchSection(
                      category: _selectedCategory,
                      controller: _searchController,
                      onChanged: (q) => _applyFilters(),
                    ),

                    const OffersBanner(),

                    PropertiesGrid(properties: _filteredFarmhouses),
                  ],
                ),
              ),
            ),
          ],
        ),

        // SearchCard is now inline/scrollable inside the ListView above.
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
            const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            const Text('Price range'),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 10000,
              divisions: 100,
              labels: RangeLabels('₹${_priceRange.start.toInt()}', '₹${_priceRange.end.toInt()}'),
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
                DropdownMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
                DropdownMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
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
                      // Apply filters and switch back to Home tab
                      _applyFilters();
                      setState(() => _selectedIndex = 0);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Apply'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset advanced filters
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

  // Helper widgets for chips and category tiles were refactored out in favor of the
  // new component widgets (CategoryTabs, SearchSection, OffersBanner, PropertiesGrid).
}