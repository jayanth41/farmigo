import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';
import '../widgets/image_with_fallback.dart';
import '../models/farmhouse_model.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/bookings_controller.dart';
import '../data/farmhouses_data.dart'; // ADDED: Import farmhouses data
import 'bookings_screen.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
// Reward updates are handled by BookingService during booking creation.

class FarmhouseDetailsScreen extends StatefulWidget {
  final String name;
  final String location;
  final double price;
  final String distance;
  final String imageUrl;
  final List<String>? images;
  final String? id;
  final String? ownerId;

  const FarmhouseDetailsScreen({
    super.key,
    required this.name,
    required this.location,
    required this.price,
    required this.distance,
    required this.imageUrl,
    this.images,
    required this.id,
    this.ownerId,
  });

  @override
  State<FarmhouseDetailsScreen> createState() => _FarmhouseDetailsScreenState();
}

class _FarmhouseDetailsScreenState extends State<FarmhouseDetailsScreen> {
  DateTime? selectedCheckInDate;
  DateTime? selectedCheckOutDate;
  String selectedPeopleRange = 'Below 10';
  late FavoritesController favoritesController;
  late FarmhouseModel farmhouse;
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  final Map<String, double> pricePerRange = {
    'Below 10': 8000,
    '10–15': 10000,
    '15–20': 12000,
    'Above 20': 15000,
  };

  double get calculatedPrice => pricePerRange[selectedPeopleRange] ?? 3000;

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

  static const List<String> guestPhotos = [
    'https://media.istockphoto.com/id/162137765/photo/summer-swimming-pool.jpg?s=612x612&w=0&k=20&c=Wv3DeS8S-yygZpJ6eE90iu7861DRVd177MlGTZVWd1I=',
    'https://media.istockphoto.com/id/514102692/photo/udaipur-city-palace-in-rajasthan-state-of-india.jpg?s=612x612&w=0&k=20&c=bYRDPOuf6nFgghl6VAnCn__22SFyu_atC_fiSCzVNtY=',
    'https://media.istockphoto.com/id/476988858/photo/white-architecture-on-santorini-island-greece.jpg?s=612x612&w=0&k=20&c=4M7lL6LvueQDiJtbUkIDT2AqV7kphss6O9YpFYsxTQc=',
    'https://media.istockphoto.com/id/2156753581/photo/creative-composition-of-living-room-interior-with-kitchen-space-and-lobby-in-the-modern.jpg?s=612x612&w=0&k=20&c=ysbREUGzXC0IeNko4TLj4_RFiZnGlq7tjqOXr2Liu3Q=',
  ];

  List<Map<String, dynamic>> similarFarmhouses = [];
  late Razorpay _razorpay;
  static const String _razorpayKey = 'rzp_live_SBLnYIO8JTlM7O'; // replace with live key when available
  Map<String, dynamic>? _pendingBooking;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      final imagesLength = widget.images?.length ?? 1;
      if (imagesLength <= 1) return;

      int nextPage = _currentPage + 1;
      if (nextPage >= imagesLength) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

  
  final user = FirebaseAuth.instance.currentUser;
  debugPrint("USER ID = ${user?.uid}");

    try {
      favoritesController = Get.find<FavoritesController>();
    } catch (e) {
      Get.put(FavoritesController());
      favoritesController = Get.find<FavoritesController>();
    }
    farmhouse = FarmhouseModel(
      id: widget.id!,
      name: widget.name,
      location: widget.location,
      price: widget.price,
      distance: widget.distance,
      imageUrl: widget.imageUrl,
    );

    // ADDED: Load similar farmhouses
    _loadSimilarFarmhouses();

    // Initialize Razorpay
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    } catch (_) {}

    // Determine if the user should be treated as a guest (signed-in but missing user doc or fetch error)
    _determineGuest();
  }

  Future<void> _determineGuest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isGuest = false;
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (!doc.exists || doc.data() == null) {
        setState(() => _isGuest = true);
      } else {
        setState(() => _isGuest = false);
      }
    } catch (e) {
      debugPrint('Failed to load user doc for guest determination: $e');
      if (mounted) setState(() => _isGuest = true);
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    try {
      _razorpay.clear();
    } catch (_) {}
    super.dispose();
  }

  // Open Razorpay checkout with given amount (in app currency units)
 void _openCheckout(num amount) {
  final user = FirebaseAuth.instance.currentUser;

  var options = {
    'key': _razorpayKey,
    'amount': (amount * 100).toInt(), // PAISA
    'name': "Skybase",
    'description': widget.name,
    'prefill': {
      'contact': user?.phoneNumber ?? '9999999999',
      'email': user?.email ?? 'test@example.com',
    },
    'theme': {'color': '#00A86B'}
  };

  try {
    _razorpay.open(options);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Razorpay error: $e")),
    );
  }
}


  // Called when payment is successful. Create booking document and increment user count.
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBooking == null) return;

    final bookingsController = Get.find<BookingsController>();
    final success = await bookingsController.addBooking(
      listingId: _pendingBooking!['listingId'],
      propertyName: _pendingBooking!['propertyName'],
      location: _pendingBooking!['location'],
      imageUrl: _pendingBooking!['imageUrl'],
      ownerId: _pendingBooking!['ownerId'],
      checkIn: _pendingBooking!['checkIn'],
      checkOut: _pendingBooking!['checkOut'],
      totalPrice: _pendingBooking!['totalPrice'],
    );

    if (!mounted) return;

    if (success) {
      // increment bookingsCount on user (use set with merge to be safe)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'bookingsCount': FieldValue.increment(1),
          }, SetOptions(merge: true));
        } catch (_) {
          // ignore increment failure
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking successful')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BookingsScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking failed after payment. Contact support.')),
      );
    }

    _pendingBooking = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment failed'),
        content: Text('Payment failed: ${response.message ?? response.code.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _pendingBooking = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  // ADDED: Method to load similar farmhouses
// COPY THIS ENTIRE METHOD to replace the existing _loadSimilarFarmhouses() in your farmhouse_details_screen.dart

  // ADDED: Method to load similar farmhouses
  void _loadSimilarFarmhouses() {
    try {
      // Get the farmhouses list from data file
      const allFarmhouses = farmhousesData;

      // Extract state from location
      final currentState = _getStateFromLocation(widget.location);

      debugPrint('[DEBUG] Current state: $currentState, Current price: ${widget.price}');

      // Filter similar farmhouses based on:
      // 1. Same state
      // 2. Similar price range (within 50% of current price)
      // 3. Exclude the current farmhouse
      final filtered = allFarmhouses.where((farm) {
        // Don't include the current farmhouse
        if (farm['name'] == widget.name) {
          debugPrint('[DEBUG] Skipping current: ${farm['name']}');
          return false;
        }

        final farmState = farm['state'] ?? '';
        final farmPrice = (farm['price'] as num).toDouble();
        
        // Same state check
        if (farmState != currentState) {
          debugPrint('[DEBUG] Different state: ${farm['name']} is $farmState');
          return false;
        }

        // Similar price range (±50%)
        final currentPrice = widget.price;
        final minPrice = currentPrice * 0.5;
        final maxPrice = currentPrice * 1.5;

        if (farmPrice < minPrice || farmPrice > maxPrice) {
          debugPrint('[DEBUG] Outside price range: ${farm['name']} is ₹$farmPrice (range: ₹$minPrice - ₹$maxPrice)');
          return false;
        }

        debugPrint('[DEBUG] MATCH: ${farm['name']} - State: $farmState, Price: ₹$farmPrice');
        return true;
      }).toList();

      debugPrint('[DEBUG] Found ${filtered.length} similar farmhouses');

      // Take only first 3 and convert to display format
      setState(() {
        similarFarmhouses = filtered.take(3).map((farm) {
          // Handle images - ensure it's a List<String>
          List<String> images = [];
          if (farm['images'] != null && farm['images'] is List) {
            try {
              images = List<String>.from(farm['images'].map((i) => i.toString()));
            } catch (e) {
              debugPrint('[DEBUG] Error converting images: $e');
              images = [];
            }
          }

          return {
            'name': farm['name'] ?? 'Unknown',
            'location': farm['location'] ?? 'Unknown',
            'image': farm['imageUrl'] ?? '',
            'price': (farm['price'] as num?)?.toDouble() ?? 0.0,
            'rating': (farm['rating'] as num?)?.toDouble() ?? 0.0,
            'reviews': farm['reviews'] ?? 0,
            'distance': farm['distance'] ?? 'N/A',
            'state': farm['state'] ?? 'Unknown',
            'category': farm['category'] ?? 'Unknown',
            'amenities': farm['amenities'] ?? [],
            'images': images,
          };
        }).toList();
      });

      debugPrint('Loaded ${similarFarmhouses.length} similar farmhouses');
    } catch (e) {
      debugPrint('Error loading similar farmhouses: $e');
    }
  }

  // ADDED: Helper method to get state from location
  String _getStateFromLocation(String location) {
    // Map locations to states
    final stateMap = {
      'Anajpur': 'Telangana',
      'Tandur': 'Telangana',
      'Yadagirigutta': 'Telangana',
      'Vikarabad': 'Telangana',
      'Hyderabad': 'Telangana',
      'Secunderabad': 'Telangana',
      'Lonavala': 'Maharashtra',
      'Goa': 'Goa',
    };

    // Extract first part of location
    final firstPart = location.split(',').first.trim();
    return stateMap[firstPart] ?? 'Telangana';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: (widget.images?.isNotEmpty ?? false)
                        ? widget.images!.length
                        : 1,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final imageUrl = (widget.images?.isNotEmpty ?? false)
                          ? widget.images![index]
                          : widget.imageUrl;

                      return ImageWithFallback(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.2),
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
                      Obx(
                        () => GestureDetector(
                          onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final currentUser = FirebaseAuth.instance.currentUser;
                                if (currentUser == null || _isGuest) {
                                  messenger.showSnackBar(const SnackBar(content: Text('Complete your profile or login to save favorites')));
                                  if (currentUser == null) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                                  } else {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                                  }
                                  return;
                                }

                                await favoritesController.toggleFavorite(
                                  FarmhouseModel(
                                    id: widget.id!,
                                    name: widget.name,
                                    location: widget.location,
                                    price: widget.price,
                                    distance: widget.distance,
                                    imageUrl: widget.imageUrl,
                                  ),
                                );
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      favoritesController.isFavorited(farmhouse.id)
                                          ? '❤️ Added to favorites'
                                          : '💔 Removed from favorites',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              favoritesController.isFavorited(farmhouse.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: favoritesController.isFavorited(farmhouse.id)
                                  ? Colors.red
                                  : Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            Text(
                              widget.distance,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                                selectedCheckOutDate = null;
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
                        GestureDetector(
                          onTap: selectedCheckInDate != null
                              ? () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedCheckInDate!
                                        .add(const Duration(days: 1)),
                                    firstDate: selectedCheckInDate!
                                        .add(const Duration(days: 1)),
                                    lastDate: selectedCheckInDate!.add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      selectedCheckOutDate = picked;
                                    });
                                  }
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedCheckInDate != null
                                    ? Colors.blue[300]!
                                    : Colors.grey[300]!,
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
                                      'Check-out Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedCheckOutDate != null
                                          ? '${selectedCheckOutDate!.day}/${selectedCheckOutDate!.month}/${selectedCheckOutDate!.year}'
                                          : 'Select date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: selectedCheckInDate != null
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: selectedCheckInDate != null
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue[300]!,
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: selectedPeopleRange,
                            isExpanded: true,
                            underline: Container(),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.blue,
                              size: 24,
                            ),
                            items: <String>[
                              'Below 10',
                              '10–15',
                              '15–20',
                              'Above 20'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedPeopleRange = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                              '₹${calculatedPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For $selectedPeopleRange people',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
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
                                child: ImageWithFallback(
                                  imageUrl: guestPhotos[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color.fromRGBO(0, 0, 0, 0.3),
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
                  const Text(
                    'Similar Farmhouses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  similarFarmhouses.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No similar properties found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: similarFarmhouses.length,
                          itemBuilder: (context, index) {
                            final farmhouse = similarFarmhouses[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FarmhouseDetailsScreen(
                                      id: farmhouse['name'],
                                      name: farmhouse['name'],
                                      location: farmhouse['location'],
                                      price: (farmhouse['price'] as num)
                                          .toDouble(),
                                      distance: farmhouse['distance'],
                                      imageUrl: farmhouse['image'],
                                      images: farmhouse['images'] ?? [],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
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
                                      child: ImageWithFallback(
                                        imageUrl: farmhouse['image'],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            Text(
                                              farmhouse['location'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
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
                                              '₹${farmhouse['price'].toStringAsFixed(0)}/night',
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null || _isGuest) {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(const SnackBar(content: Text('Complete your profile or login to make bookings')));
              if (currentUser == null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }
              return;
            }
            if (widget.id == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Invalid property")),
              );
              return;
            }

            if (selectedCheckInDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select a check-in date")),
              );
              return;
            }

            // Prepare pending booking data and open Razorpay checkout.
            // The actual booking document will be created only after payment success.
            _pendingBooking = {
              'listingId': widget.id!,
              'propertyName': widget.name,
              'location': widget.location,
              'imageUrl': widget.imageUrl,
              'ownerId': widget.ownerId,
              'checkIn': selectedCheckInDate?.toIso8601String() ?? '',
              'checkOut': selectedCheckOutDate?.toIso8601String() ?? '',
              'totalPrice': calculatedPrice,
              'paidAt': Timestamp.now(),
            };

            _openCheckout(calculatedPrice);
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