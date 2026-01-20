import 'package:flutter/material.dart';

import '../models/car_rental.dart';
import '../widgets/car_rental_card.dart';
import '../theme/app_colors.dart';

class CarRentalsScreen extends StatelessWidget {
  const CarRentalsScreen({super.key});

  // Dummy static data
  static final List<CarRental> _dummyCars = const [
    CarRental(
      id: 'swift_dzire',
      name: 'Swift Dzire',
      type: 'Sedan',
      location: 'Hyderabad, Telangana',
      rating: 4.3,
      reviews: 128,
      features: ['AC', 'Driver', 'Fuel Included'],
      pricePerDay: 2200,
      imageUrl: 'https://images.unsplash.com/photo-1542365887-4fa2588d4f6a?auto=format&fit=crop&w=1200&q=80',
      discountPercent: 10,
    ),
    CarRental(
      id: 'innova_crysta',
      name: 'Innova Crysta',
      type: 'SUV',
      location: 'Secunderabad, Telangana',
      rating: 4.7,
      reviews: 254,
      features: ['AC', 'Driver', 'Spacious'],
      pricePerDay: 4200,
      imageUrl: 'https://images.unsplash.com/photo-1472291025161-3c9e1d76d51c?auto=format&fit=crop&w=1200&q=80',
      discountPercent: 15,
    ),
    CarRental(
      id: 'alto',
      name: 'Maruti Alto',
      type: 'Hatchback',
      location: 'Warangal, Telangana',
      rating: 4.0,
      reviews: 64,
      features: ['AC', 'Self Drive'],
      pricePerDay: 1500,
      imageUrl: 'https://images.unsplash.com/photo-1511910849309-0d5f7c1d6d20?auto=format&fit=crop&w=1200&q=80',
    ),
    CarRental(
      id: 'endeavour',
      name: 'Ford Endeavour',
      type: 'SUV',
      location: 'Nizamabad, Telangana',
      rating: 4.5,
      reviews: 98,
      features: ['AC', 'Driver', 'Fuel Included'],
      pricePerDay: 4800,
      imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80',
      discountPercent: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Car Rentals',
          style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _dummyCars.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final car = _dummyCars[index];
          return CarRentalCard(car: car);
        },
      ),
    );
  }
}
