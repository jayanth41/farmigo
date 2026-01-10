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

  // Dummy farmhouse data
  static const List<Map<String, dynamic>> farmhouses = [
    {
      'name': 'The Night Garden Stay',
      'location': 'Anajpur, Hyderabad',
      'price': 10000.0,
      'distance': '15 km away',
      'imageUrl': 
        'https://raw.githubusercontent.com/jayanth41/images/main/view2.jpeg',
       // 'https://raw.githubusercontent.com/jayanth41/images/main/dyning.jpeg',
    },
    {
      'name': 'Serene Hills Resort',
      'location': 'Hyderabad, Telangana',
      'price': 3500.0,
      'distance': '8 km away',
      'imageUrl':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500&h=300',
    },
    {
      'name': 'Organic Farm Retreat',
      'location': 'Tandur, Telangana',
      'price': 1800.0,
      'distance': '25 km away',
      'imageUrl':
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=500&h=300',
    },
    {
      'name': 'Riverside Farmhouse',
      'location': 'Yadagirigutta, Telangana',
      'price': 2800.0,
      'distance': '35 km away',
      'imageUrl':
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=300',
    },
    {
      'name': 'Heritage Farm Stay',
      'location': 'Vikarabad, Telangana',
      'price': 2200.0,
      'distance': '45 km away',
      'imageUrl':
          'https://images.unsplash.com/photo-1469022563149-aa64dbd37dda?w=500&h=300',
    },
    {
      'name': 'Premium Agri Resort',
      'location': 'Narayankhed, Telangana',
      'price': 4000.0,
      'distance': '60 km away',
      'imageUrl':
          'https://images.unsplash.com/photo-1494783367193-149034c05e41?w=500&h=300',
    },
  ];

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
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
                    hintText: 'Search farmhouses...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF4A7023),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                _buildFilterChip('All', true),
                _buildFilterChip('Under ₹2000', false),
                _buildFilterChip('Within 20km', false),
                _buildFilterChip('Luxury', false),
              ],
            ),
          ),
          // Farmhouse List
          Expanded(
            child: ListView.builder(
              itemCount: farmhouses.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final farmhouse = farmhouses[index];
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
      ),
      // Bottom Navigation Bar
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
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4A7023),
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
            label: 'Filters',
          ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
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
        onSelected: (value) {
          // TODO: Implement filter logic
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
