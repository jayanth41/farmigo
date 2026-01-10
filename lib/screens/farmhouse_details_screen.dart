import 'package:flutter/material.dart';

class FarmhouseDetailsScreen extends StatefulWidget {
  final String name;
  final String location;
  final double price;
  final String distance;
  final String imageUrl;

  const FarmhouseDetailsScreen({
    super.key,
    required this.name,
    required this.location,
    required this.price,
    required this.distance,
    required this.imageUrl,
  });

  @override
  State<FarmhouseDetailsScreen> createState() => _FarmhouseDetailsScreenState();
}

class _FarmhouseDetailsScreenState extends State<FarmhouseDetailsScreen> {
  DateTime? selectedCheckInDate;
  int numberOfPeople = 2;

  // Dummy amenities data
  static const List<Map<String, dynamic>> amenities = [
    {'icon': Icons.wifi, 'name': 'Free WiFi'},
    {'icon': Icons.kitchen, 'name': 'Full Kitchen'},
    {'icon': Icons.pool, 'name': 'Swimming Pool'},
    {'icon': Icons.hot_tub, 'name': 'Hot Tub'},
    {'icon': Icons.sports_cricket, 'name': 'Sports Area'},
    {'icon': Icons.local_parking, 'name': 'Parking'},
    {'icon': Icons.ac_unit, 'name': 'AC Rooms'},
    {'icon': Icons.restaurant, 'name': 'Restaurant'},
  ];

  // Dummy guest photos
  static const List<String> guestPhotos = [
    'https://via.placeholder.com/150',
    'https://via.placeholder.com/150',
    'https://via.placeholder.com/150',
    'https://via.placeholder.com/150',
  ];

  // Dummy similar farmhouses
  static const List<Map<String, dynamic>> similarFarmhouses = [
    {
      'name': 'Green Valley Farmhouse',
      'price': 3500,
      'rating': 4.8,
      'reviews': 156,
      'image': 'https://via.placeholder.com/200x150'
    },
    {
      'name': 'Countryside Retreat',
      'price': 4200,
      'rating': 4.6,
      'reviews': 89,
      'image': 'https://via.placeholder.com/200x150'
    },
    {
      'name': 'Rural Paradise',
      'price': 3800,
      'rating': 4.9,
      'reviews': 234,
      'image': 'https://via.placeholder.com/200x150'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Image with Back Button
            Stack(
              children: [
                Image.network(
                  widget.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
                // Back Button
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Google Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.location,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  widget.distance,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.open_in_new,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Open in Google Maps',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Check-in Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-In Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Check-in Date
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedCheckInDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Check-in Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedCheckInDate != null
                                          ? '${selectedCheckInDate!.day}/${selectedCheckInDate!.month}/${selectedCheckInDate!.year}'
                                          : 'Select date',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Number of Guests
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Number of People',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    numberOfPeople.toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: numberOfPeople > 1
                                        ? () {
                                            setState(() {
                                              numberOfPeople--;
                                            });
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: numberOfPeople < 10
                                        ? () {
                                            setState(() {
                                              numberOfPeople++;
                                            });
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Price Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price per night',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '₹${widget.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Amenities Title
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Amenities Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: amenities.length,
                    itemBuilder: (context, index) {
                      final amenity = amenities[index];
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              amenity['icon'],
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            amenity['name'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Description and Ratings
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Experience a serene farmhouse getaway in beautiful Telangana. Perfect for family vacations, weekend escapes, and corporate retreats. Our farmhouse offers comfortable rooms, delicious meals, and various recreational activities.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ratings Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ratings & Reviews',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '4.7',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (index) => Icon(
                                          index < 4 ? Icons.star : Icons.star_half,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '428 Reviews',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Guest Photos Section
                  const Text(
                    'Guest Photos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: guestPhotos.length + 1,
                      itemBuilder: (context, index) {
                        if (index == guestPhotos.length) {
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'More',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[300],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  guestPhotos[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Similar Farmhouses Section
                  const Text(
                    'Similar Farmhouses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: similarFarmhouses.length,
                    itemBuilder: (context, index) {
                      final farmhouse = similarFarmhouses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: Image.network(
                                farmhouse['image'],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      farmhouse['name'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${farmhouse['rating']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${farmhouse['reviews']})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₹${farmhouse['price']}/night',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      // Book Now Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            print('Book Now tapped for: ${widget.name}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Booking ${widget.name} for $numberOfPeople person(s)${selectedCheckInDate != null ? ' on ${selectedCheckInDate!.day}/${selectedCheckInDate!.month}' : ''}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Book Now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
