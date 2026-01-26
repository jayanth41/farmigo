import 'package:flutter/material.dart';
import '../widgets/properties_grid.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_colors.dart';

/// Screen that shows a list of farmhouses (dummy data copied from Home).
class FarmhousesScreen extends StatelessWidget {
  const FarmhousesScreen({super.key});

  static const List<Map<String, dynamic>> _farmhouses = [
    {
      'id': '11111111-1111-1111-1111-111111111111',
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
      'id': '22222222-2222-2222-2222-222222222222',
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
      'id': '33333333-3333-3333-3333-333333333333',
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
      'id': '44444444-4444-4444-4444-444444444444',
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Farmhouses'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: ListView(
          children: [
            PropertiesGrid(properties: _farmhouses),
          ],
        ),
      ),
    );
  }
}