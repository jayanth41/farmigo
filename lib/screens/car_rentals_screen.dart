import 'package:flutter/material.dart';

import '../models/car_rental.dart';
import '../widgets/car_rental_card.dart';

class CarRentalsScreen extends StatelessWidget {
  const CarRentalsScreen({super.key});

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
      imageUrl: 'https://via.placeholder.com/1200x800.png?text=Car+Image',
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
      imageUrl: 'https://via.placeholder.com/1200x800.png?text=Car+Image',
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
      imageUrl: 'https://via.placeholder.com/1200x800.png?text=Car+Image',
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
      imageUrl: 'https://via.placeholder.com/1200x800.png?text=Car+Image',
      discountPercent: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Car Rentals',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _dummyCars.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final car = _dummyCars[index];
          return CarRentalCard(car: car);
        },
      ),
    );
  }
}
