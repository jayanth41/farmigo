import 'package:flutter/material.dart';
import '../models/category.dart';
import 'filters_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Category _selectedCategory = Category.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FiltersScreen(
                    category: _selectedCategory,
                    onFiltersApplied: (filters) {
                      // Explore list doesn't own global filters yet.
                      // You can wire this to search results later.
                    },
                    initialFilters: const {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== SEARCH BAR =====
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search destinations...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ===== CATEGORY GRID =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Explore Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _categoryCard(context, icon: Icons.home_outlined, label: 'Farmhouses', category: Category.farmhouse),
                    _categoryCard(context, icon: Icons.villa, label: 'Villas', category: Category.villa),
                    _categoryCard(context, icon: Icons.hotel, label: 'Hotels', category: Category.hotel),
                    _categoryCard(context, icon: Icons.flight, label: 'Flights', category: Category.flights),
                    _categoryCard(context, icon: Icons.directions_car, label: 'Car Rentals', category: Category.car),
                    _categoryCard(context, icon: Icons.schedule, label: 'Hourly', category: Category.hourly),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== POPULAR NEAR YOU =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Popular Near You',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _propertyCard(
                        title: ['Mountain Escape', 'Beach Villa', 'City Loft', 'Farm Stay', 'Resort'][index],
                        price: ['\$120', '\$180', '\$95', '\$85', '\$150'][index],
                        rating: [4.8, 4.9, 4.7, 4.6, 4.9][index],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ===== TOP RATED STAYS =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Top Rated Stays',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _propertyCard(
                        title: ['Luxury Resort', 'Beachfront Hotel', 'Countryside Farm', 'Modern Villa', 'Heritage Stay'][index],
                        price: ['\$250', '\$200', '\$110', '\$175', '\$140'][index],
                        rating: [5.0, 4.9, 4.8, 4.9, 4.8][index],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Category Card Widget
  Widget _categoryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Category category,
  }) {
    final selected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected $label')),
        );
      },
        child: Container(
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor.withOpacity(0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Theme.of(context).primaryColor : Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: selected ? Theme.of(context).primaryColor : Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Theme.of(context).primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Property Card Widget
  Widget _propertyCard({
    required String title,
    required String price,
    required double rating,
  }) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image,
                color: Colors.grey[600],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
