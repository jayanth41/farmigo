import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/farmhouse_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Quick chip filter
  String _selectedFilter = 'All';

  // Advanced filter state
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _maxDistance = 100; // in km
  bool _luxuryOnly = false;
  double _minRating = 0;
  Map<String, bool> _amenities = {
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
      'price': 10000.0,
      'distance': '15 km away',
      'rating': 4.8,
      'amenities': ['Pool', 'WiFi', 'Kitchen', 'Breakfast'],
      'imageUrl':
          'https://raw.githubusercontent.com/jayanth41/images/main/view2.jpeg',
    },
    {
      'name': 'Serene Hills Resort',
      'location': 'Hyderabad, Telangana',
      'price': 3500.0,
      'distance': '8 km away',
      'rating': 4.4,
      'amenities': ['WiFi', 'Breakfast'],
      'imageUrl':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500&h=300',
    },
    {
      'name': 'Organic Farm Retreat',
      'location': 'Tandur, Telangana',
      'price': 1800.0,
      'distance': '25 km away',
      'rating': 4.0,
      'amenities': ['Kitchen', 'Breakfast'],
      'imageUrl':
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=500&h=300',
    },
    {
      'name': 'Riverside Farmhouse',
      'location': 'Yadagirigutta, Telangana',
      'price': 2800.0,
      'distance': '35 km away',
      'rating': 3.9,
      'amenities': ['WiFi', 'Kitchen'],
      'imageUrl':
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=300',
    },
    {
      'name': 'Heritage Farm Stay',
      'location': 'Vikarabad, Telangana',
      'price': 2200.0,
      'distance': '45 km away',
      'rating': 4.2,
      'amenities': ['Breakfast', 'Kitchen'],
      'imageUrl':
          'https://images.unsplash.com/photo-1469022563149-aa64dbd37dda?w=500&h=300',
    },
    {
      'name': 'Premium Agri Resort',
      'location': 'Narayankhed, Telangana',
      'price': 4000.0,
      'distance': '60 km away',
      'rating': 4.6,
      'amenities': ['Pool', 'WiFi'],
      'imageUrl':
          'https://images.unsplash.com/photo-1494783367193-149034c05e41?w=500&h=300',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredFarmhouses = List.from(farmhouses);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }

  void _onSearchChanged() => _applyFilters();

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredFarmhouses = farmhouses.where((farm) {
        final name = (farm['name'] as String).toLowerCase();
        final location = (farm['location'] as String).toLowerCase();
        final price = farm['price'] as double;
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
      backgroundColor: Colors.grey[50],
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4A7023),
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
    if (_selectedIndex == 3) return _filtersPage();

    // placeholders for other tabs
    return Center(
      child: Text(
        _selectedIndex == 1
            ? 'Favorites (not implemented yet)'
            : _selectedIndex == 2
                ? 'Bookings (not implemented yet)'
                : 'Profile (not implemented yet)',
        style: const TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _homePage() {
    return Column(
      children: [
        // Custom AppBar
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2D5016),
                Color(0xFF4A7023),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Logout Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FARMIGO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Find your perfect farmhouse retreat',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by stay name or location',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4A7023),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip('All'),
              _buildFilterChip('Under ₹2000'),
              _buildFilterChip('Within 20km'),
              _buildFilterChip('Luxury'),
            ],
          ),
        ),

        // Farmhouse List
        Expanded(
          child: _filteredFarmhouses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search_off, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "No farmhouses found",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredFarmhouses.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final farmhouse = _filteredFarmhouses[index];
                    return FarmhouseCard(
                      name: farmhouse['name'],
                      location: farmhouse['location'],
                      price: farmhouse['price'],
                      distance: farmhouse['distance'],
                      imageUrl: farmhouse['imageUrl'],
                    );
                  },
                ),
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
              label: '${_minRating.toStringAsFixed(1)}',
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
                    child: const Text('Apply'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A7023)),
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

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4A7023),
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (value) {
          setState(() {
            _selectedFilter = label;
          });
          _applyFilters();
        },
        backgroundColor: isSelected ? const Color(0xFF4A7023) : Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF4A7023) : Colors.grey[300]!,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
