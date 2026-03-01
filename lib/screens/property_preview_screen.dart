import 'package:flutter/material.dart';

class PropertyPreviewScreen extends StatelessWidget {
  const PropertyPreviewScreen({
    super.key,
    required this.propertyName,
    required this.propertyType,
    required this.description,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.pricePerNight,
    required this.bedrooms,
    required this.bathrooms,
    required this.guests,
    required this.minStay,
    required this.amenities,
    required this.photoCount,
    required this.instantBooking,
    required this.activeListing,
    required this.onConfirm,
  });

  final String propertyName;
  final String propertyType;
  final String description;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String pricePerNight;
  final String bedrooms;
  final String bathrooms;
  final String guests;
  final String minStay;
  final List<String> amenities;
  final int photoCount;
  final bool instantBooking;
  final bool activeListing;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview Property")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Photos Preview
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
              ),
              alignment: Alignment.center,
              child: Text(
                "$photoCount photo(s) selected",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(propertyName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),

                  Text("₹ $pricePerNight / night",
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),

                  const SizedBox(height: 8),

                  Text("$city, $state",
                      style: const TextStyle(color: Colors.grey)),

                  const SizedBox(height: 16),

                  const Text("Description",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 6),

                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text("Confirm & Publish"),
        ),
      ),
    );
  }
}