import 'package:flutter/material.dart';
import '../widgets/image_with_fallback.dart';
import '../widgets/app_drawer.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String name;
  final String category;
  final String location;
  final double price;
  final double rating;
  final int reviews;
  final String imageUrl;
  final List<String> amenities;

  const BookingDetailsScreen({
    super.key,
    required this.name,
    required this.category,
    required this.location,
    required this.price,
    this.rating = 0.0,
    this.reviews = 0,
    required this.imageUrl,
    this.amenities = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        title: Text(name, style: const TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageWithFallback(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: const TextStyle(color:Color.fromARGB(255, 41, 70, 92), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(location, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${price.toInt()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          const Text('per night', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color:  Color.fromARGB(255, 41, 70, 92), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.star, color: Colors.white, size: 16), const SizedBox(width: 6), Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white))])),
                      const SizedBox(width: 12),
                      Text('$reviews reviews', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: amenities.map((a) => Chip(label: Text(a))).toList()),
                  const SizedBox(height: 20),
                  const Text('About this listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('This is a demo details screen for non-farmhouse listings. Replace with a dedicated design for hotels, flights, or car rentals as needed.'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking flow not implemented in demo')));
                      },
                      child: const Text('Book now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
