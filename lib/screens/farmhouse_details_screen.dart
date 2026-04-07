import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';
import '../widgets/image_with_fallback.dart';
import '../models/farmhouse_model.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/bookings_controller.dart';
import '../data/farmhouses_data.dart'; // ADDED: Import farmhouses data
import 'bookings_screen.dart';
import 'property_details_screen.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  Widget _premiumPropertyCard(
      String name, String location, String price, String image) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              image,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

  int get totalNights {
    if (selectedCheckInDate == null || selectedCheckOutDate == null) return 0;
    return selectedCheckOutDate!.difference(selectedCheckInDate!).inDays;
  }

  double get totalPrice {
    if (totalNights <= 0) return calculatedPrice;
    return calculatedPrice * totalNights;
  }

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

  // Similar farmhouses feature removed — no local state required.
  late Razorpay _razorpay;
  static const String _razorpayKey = 'rzp_live_SBLnYIO8JTlM7O'; // replace with live key when available
  Map<String, dynamic>? _pendingBooking;
  bool _isGuest = false;
  final TextEditingController _reviewController = TextEditingController();
  final List<XFile> _reviewImages = [];
  Future<void> _pickReviewImages() async {
    try {
      final images = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        setState(() {
          _reviewImages.addAll(images);
        });
      }
    } catch (e) {
      debugPrint("Review image picker error: $e");
    }
  }

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

  // Similar farmhouses loading removed.

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

  Future<void> _openGoogleMaps() async {
    final query = Uri.encodeComponent(widget.location);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      debugPrint("Maps launch error: $e");
    }
  }

  void _shareProperty() {
    final text =
        "${widget.name}\nLocation: ${widget.location}\nPrice: ₹${widget.price.toStringAsFixed(0)} per night\n\nCheck this property on Skybase!";
    Share.share(text);
  }

  void _showMapPreview() {
    final query = Uri.encodeComponent(widget.location);
    final mapUrl =
        "https://www.google.com/maps/search/?api=1&query=$query";

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Property Location",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "https://maps.googleapis.com/maps/api/staticmap?center=$query&zoom=14&size=600x400&markers=color:red|$query",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text("Map preview not available"),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Location label
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.location,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: _openGoogleMaps,
                    icon: const Icon(Icons.map),
                    label: const Text("Open in Google Maps"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
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

  // Similar farmhouses feature removed. Helper methods and local seed data imports
  // that were used only for generating similar items have been removed to
  // simplify the details screen.

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
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _shareProperty,
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
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
                                Icons.share,
                                color: Colors.black,
                                size: 22,
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
                                      ?  Color(0xFF2C3E50)
                                      : Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _openGoogleMaps,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: _showMapPreview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      
                    ),
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
                  const SizedBox(height: 8),

                  // Location (moved up)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _openGoogleMaps,
                              child: Text(
                                widget.location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
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

                  const SizedBox(height: 12),

                  // Property Timings section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Property Timings",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.login, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              "Check‑in: 12:00 PM onwards",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              "Check‑out: Before 11:00 AM",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              "Support available: 24 × 7",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location row moved above, so remove this block.

                  // Owner / Host Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Managed by",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Usually responds within 10 minutes",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "🟢 Online",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      if (widget.ownerId == null || widget.ownerId!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Owner chat not available')),
                        );
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening chat with owner...')),
                      );

                      // Future navigation
                      // Navigator.push(context, MaterialPageRoute(
                      //   builder: (_) => OwnerChatScreen(ownerId: widget.ownerId!),
                      // ));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.chat_bubble_outline, color: Colors.black),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Chat with Owner",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                              color:  Color.fromARGB(255, 107, 145, 183),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              amenity['icon'],
                              color:  Color(0xFF2C3E50),
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
                    'Why to Choose Us??',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Peaceful location perfect for weekend getaways",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Spacious property ideal for families & groups",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Premium amenities like pool, kitchen and sports area",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Highly rated by guests for cleanliness and comfort",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Policies / House Rules (temporary static section)
                  const SizedBox(height: 20),
                  const Text(
                    'Policies & House Rules',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.rule, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "No loud music after 10:00 PM",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.local_bar, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Alcohol allowed only in designated areas",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.pets, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Pets allowed only with prior permission",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.group, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Maximum guest limit must be respected",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Cancellation Policy section
                  const SizedBox(height: 20),

                  // Cancellation Policy (temporary static section)
                  const Text(
                    'Cancellation Policy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Free cancellation up to 48 hours before check-in",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "50% refund if cancelled within 24–48 hours before check-in",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "No refund for cancellations within 24 hours of check-in",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // FAQs section (TEMPORARY, static)
                  const SizedBox(height: 28),
                  const Text(
                    'FAQs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text(
                      "What is the check-in and check-out time?",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          "Check-in starts from 12:00 PM and check-out is before 11:00 AM.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                  ExpansionTile(
                    title: const Text(
                      "Are outside food and drinks allowed?",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          "Yes, outside food is allowed. However, we recommend trying the in-house meals available.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                  ExpansionTile(
                    title: const Text(
                      "Is parking available at the property?",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          "Yes, free parking is available for guests inside the property premises.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                  ExpansionTile(
                    title: const Text(
                      "Is the property suitable for parties or events?",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          "Yes, small gatherings and private parties are allowed depending on the property rules.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!, width: 1),
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
                                color: Colors.green,
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

                  const SizedBox(height: 20),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Guest Photos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                insetPadding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    itemCount: guestPhotos.length,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ImageWithFallback(
                                          imageUrl: guestPhotos[index],
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: const Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
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

                  const Text(
                    'Write a Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _reviewController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: "Share your experience...",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          children: _reviewImages.map((img) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(img.path),
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickReviewImages,
                              icon: const Icon(Icons.photo),
                              label: const Text("Add Photos"),
                            ),

                            const Spacer(),

                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Review submitted")),
                                );
                              },
                              child: const Text("Submit"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),


                  // Nearby Attractions (temporary static list)
                  const Text(
                    'Nearby Attractions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.place, color: Colors.teal),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Hill View Point – 3 km",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.park, color: Colors.teal),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Nature Park – 5 km",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.water, color: Colors.teal),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Lake View Point – 7 km",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.temple_hindu, color: Colors.teal),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Ancient Temple – 4 km",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Premium Recommendation Section
                  const SizedBox(height: 28),
                  const Text(
                    'People also booked',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 170,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _premiumPropertyCard(
                          "Lake View Villa",
                          "Lonavala",
                          "₹9000",
                          "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800",
                        ),
                        _premiumPropertyCard(
                          "Green Valley Farmhouse",
                          "Hyderabad",
                          "₹7500",
                          "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
                        ),
                        _premiumPropertyCard(
                          "Hilltop Retreat",
                          "Goa",
                          "₹8200",
                          "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800",
                        ),
                      ],
                    ),
                  ),

                  // Similar farmhouses removed. Extra spacing retained.
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (totalNights > 0) ...[
                    Text(
                      '₹${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '₹${calculatedPrice.toStringAsFixed(0)} × $totalNights nights',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '₹${calculatedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'per night',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;

                  if (currentUser == null || _isGuest) {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Complete your profile or login to make bookings')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
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

                  showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          final TextEditingController specialRequestController =
                              TextEditingController();
                          final TextEditingController otherGuestNameController =
                              TextEditingController();
                          final TextEditingController otherGuestPhoneController =
                              TextEditingController();

                          bool bookingForSomeoneElse = false;
                          XFile? idProof;

                          Future<void> pickIdProof() async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (picked != null) {
                              setState(() {
                                idProof = picked;
                              });
                            }
                          }

                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              "Booking Summary",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// PROPERTY DETAILS
                                    const Text(
                                      "Property Details",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(widget.name),
                                    Text(widget.location),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Check‑in: ${selectedCheckInDate!.day}/${selectedCheckInDate!.month}/${selectedCheckInDate!.year}",
                                    ),
                                    Text(
                                      selectedCheckOutDate != null
                                          ? "Check‑out: ${selectedCheckOutDate!.day}/${selectedCheckOutDate!.month}/${selectedCheckOutDate!.year}"
                                          : "Check‑out: Not selected",
                                    ),
                                    Text("Guests: $selectedPeopleRange"),

                                    const Divider(height: 24),

                                    /// RULES
                                    const Text(
                                      "Property Rules",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text("• No loud music after 10 PM"),
                                    const Text("• Alcohol only in designated areas"),
                                    const Text("• Follow guest capacity limits"),

                                    const Divider(height: 24),

                                    /// PRICE BREAKDOWN
                                    const Text(
                                      "Price Details",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text("₹${calculatedPrice.toStringAsFixed(0)} × $totalNights nights"),
                                    const Text("Service fee ₹500"),
                                    const Text("Taxes ₹350"),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Total ₹${totalPrice.toStringAsFixed(0)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),

                                    const Divider(height: 24),

                                    /// BOOKING FOR
                                    const Text(
                                      "Booking For",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(FirebaseAuth.instance.currentUser?.email ?? "User"),

                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        Checkbox(
                                          value: bookingForSomeoneElse,
                                          onChanged: (v) {
                                            setState(() {
                                              bookingForSomeoneElse = v ?? false;
                                            });
                                          },
                                        ),
                                        const Text("Booking for someone else"),
                                      ],
                                    ),

                                    if (bookingForSomeoneElse) ...[
                                      TextField(
                                        controller: otherGuestNameController,
                                        decoration: const InputDecoration(
                                          labelText: "Guest Name",
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: otherGuestPhoneController,
                                        decoration: const InputDecoration(
                                          labelText: "Guest Phone",
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    /// SPECIAL REQUEST
                                    const Text(
                                      "Special Request",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: specialRequestController,
                                      maxLines: 2,
                                      decoration: const InputDecoration(
                                        hintText: "Decoration, early check-in, etc.",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    /// ID PROOF
                                    const Text(
                                      "Upload Aadhaar / ID Proof",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: pickIdProof,
                                          icon: const Icon(Icons.upload),
                                          label: const Text("Upload"),
                                        ),
                                        const SizedBox(width: 10),
                                        if (idProof != null)
                                          const Text(
                                            "ID selected",
                                            style: TextStyle(color: Colors.green),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);

                                  _pendingBooking = {
                                    'listingId': widget.id!,
                                    'propertyName': widget.name,
                                    'location': widget.location,
                                    'imageUrl': widget.imageUrl,
                                    'ownerId': widget.ownerId,
                                    'checkIn': selectedCheckInDate?.toIso8601String() ?? '',
                                    'checkOut': selectedCheckOutDate?.toIso8601String() ?? '',
                                    'totalPrice': totalPrice,
                                    'paidAt': Timestamp.now(),
                                  };

                                  _openCheckout(totalPrice);
                                },
                                child: Text("Confirm & Pay ₹${totalPrice.toStringAsFixed(0)}"),
                              ),
                            ],
                          );
                        },
                      );
                    },
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
          ],
        ),
      ),
    );
  }
}