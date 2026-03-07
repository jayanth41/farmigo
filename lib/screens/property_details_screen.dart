import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart' as share;
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../services/faq_service.dart';
import '../services/review_service_complete.dart';
import '../services/chat_service.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;
  final String? currentUserId;

  const PropertyDetailsScreen({
    super.key,
    required this.propertyId,
    this.currentUserId,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PropertyService _propertyService = PropertyService();
  final FAQService _faqService = FAQService();
  final ReviewServiceComplete _reviewService = ReviewServiceComplete();
  final ChatService _chatService = ChatService();

  late PropertyModel property;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('\n🔍 PropertyDetailsScreen initialized');
    debugPrint('   propertyId: ${widget.propertyId}');
    debugPrint('   currentUserId: ${widget.currentUserId}\n');
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    try {
      debugPrint('🔄 Loading property from Firestore: ${widget.propertyId}');
      final prop = await _propertyService.getPropertyById(widget.propertyId);
      if (prop != null) {
        setState(() {
          property = prop;
          isLoading = false;
          errorMessage = null;
        });
        _checkEligibleForReview();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Property not found. Please check the property ID.';
        });
      }
    } catch (e) {
      debugPrint('Error loading property: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading property: $e';
      });
    }
  }

  Future<void> _checkEligibleForReview() async {
    if (widget.currentUserId == null) return;
    try {
      final now = DateTime.now();
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: widget.currentUserId)
          .where('listingId', isEqualTo: widget.propertyId)
          .where('status', isEqualTo: 'completed')
          .get();

      bool hasCompletedStay = false;
      for (var doc in bookingsSnapshot.docs) {
        final checkOutTimestamp = doc.data()['checkOut'] as Timestamp?;
        if (checkOutTimestamp != null && checkOutTimestamp.toDate().isBefore(now)) {
          hasCompletedStay = true;
          break;
        }
      }

      if (hasCompletedStay) {
        final reviews = await _reviewService.getReviewsByPropertyId(widget.propertyId);
        final hasReviewed = reviews.any((r) => r.userId == widget.currentUserId);
        
        if (!hasReviewed && mounted) {
           _showReviewDialog(promptRating: true);
        }
      }
    } catch (e) {
      debugPrint('Error checking review eligibility: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  _loadProperty();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Gallery
            _buildImageGallery(),

            // Debug banner to confirm loaded property data (only in debug mode)
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Debug: propertyId = ${widget.propertyId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Loaded name: ${property.name}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Images: ${property.imageUrls.length}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Title + Rating + Share
                  _buildTitleSection(),
                  const SizedBox(height: 16),

                  // Chat with Owner Button
                  _buildChatButton(),
                  const SizedBox(height: 16),

                  // 3. Managed By Section
                  _buildManagedBySection(),
                  const SizedBox(height: 24),

                  // 4. Highlights Section
                  _buildHighlightsSection(),
                  const SizedBox(height: 24),

                  // 5. Why Choose Us Section
                  _buildWhyChooseUsSection(),
                  const SizedBox(height: 24),

                  // 6. Price Overview
                  _buildPriceOverviewSection(),
                  const SizedBox(height: 24),

                  // 7. Timings Section
                  _buildTimingsSection(),
                  const SizedBox(height: 24),

                  // 8. Amenities Section
                  _buildAmenitiesSection(),
                  const SizedBox(height: 24),

                  // 9. Description
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),

                  // 10. Google Map
                  _buildMapSection(),
                  const SizedBox(height: 24),

                  // 11. Nearby Attractions
                  _buildNearbyAttractionsSection(),
                  const SizedBox(height: 24),

                  // 12. FAQs
                  _buildFAQsSection(),
                  const SizedBox(height: 24),

                  // 13. Policies Section
                  _buildPoliciesSection(),
                  const SizedBox(height: 24),

                  // 14. Reviews Section
                  _buildReviewsSection(),
                  const SizedBox(height: 24),

                  // Similar properties removed
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFixedBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Property Details'),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareProperty,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // Add to favorites
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to favorites!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: property.imageUrls.isEmpty ? 1 : property.imageUrls.length,
        itemBuilder: (context, index) {
          if (property.imageUrls.isEmpty) {
            return Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.image, size: 80, color: Colors.grey),
            );
          }
          return Image.network(
            property.imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              property.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${property.reviewCount} reviews)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${property.city}, ${property.state}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat with Owner'),
        onPressed: widget.currentUserId != null ? _openChat : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _openChat() async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to chat')),
      );
      return;
    }

    final chat = await _chatService.getOrCreateChat(
      propertyId: widget.propertyId,
      userId: widget.currentUserId!,
      ownerId: property.userId,
    );

    if (chat != null && mounted) {
      // Navigate to chat screen - implement your navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened chat with owner')),
      );
    }
  }

  Widget _buildManagedBySection() {
    final ownerName = property.ownerDetails?['name'] ?? 'Property Owner';
    final isVerified = property.ownerDetails?['isVerified'] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Managed By',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                  property.ownerDetails?['image'] ?? '',
                ),
                radius: 24,
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ownerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.ownerDetails?['contact'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    if (property.highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Highlights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: property.highlights
              .map(
                (highlight) => Chip(
                  label: Text(highlight),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: const TextStyle(color: Colors.blue),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildWhyChooseUsSection() {
    final reasons = [
      ('24/7 Support', Icons.support_agent),
      ('Secure Payments', Icons.security),
      ('Verified Properties', Icons.verified_user),
      ('Best Value', Icons.price_check),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why Choose Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: reasons
              .map(
                (reason) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        reason.$2,
                        color: Colors.blue,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPriceOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${property.pricePerNight.toStringAsFixed(0)}/night',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Including taxes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsSection() {
    final checkIn = property.timings['checkInTime'] ?? 'N/A';
    final checkOut = property.timings['checkOutTime'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimingCard('Check-in', checkIn, Icons.login),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimingCard('Check-out', checkOut, Icons.logout),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimingCard(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    if (property.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: property.amenities
              .map(
                (amenity) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    amenity,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          property.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 300,
            child: maps.GoogleMap(
              initialCameraPosition: maps.CameraPosition(
                target: maps.LatLng(property.latitude, property.longitude),
                zoom: 14,
              ),
              markers: {
                maps.Marker(
                  markerId: const maps.MarkerId('propertyLocation'),
                  position: maps.LatLng(property.latitude, property.longitude),
                  infoWindow: maps.InfoWindow(title: property.name),
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyAttractionsSection() {
    if (property.nearbyAttractions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Attractions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: property.nearbyAttractions.length,
            itemBuilder: (context, index) {
              final attraction = property.nearbyAttractions[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (attraction.imageUrl != null)
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade200,
                          child: Image.network(
                            attraction.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attraction.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${attraction.distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFAQsSection() {
    return FutureBuilder(
      future: _faqService.getFAQsByPropertyId(widget.propertyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final faqs = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...faqs.map((faq) => ExpansionTile(
              title: Text(
                faq.question,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    faq.answer,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            )),
          ],
        );
      },
    );
  }

  Widget _buildPoliciesSection() {
    final checkInPolicy = property.policies['checkInPolicy'] ?? 'N/A';
    final checkOutPolicy = property.policies['checkOutPolicy'] ?? 'N/A';
    final cancellationPolicy =
        property.policies['cancellationPolicy'] ?? 'N/A';
    final houseRules = property.policies['houseRules'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Policies & Rules',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPolicyCard('Check-In Policy', checkInPolicy),
        const SizedBox(height: 12),
        _buildPolicyCard('Check-Out Policy', checkOutPolicy),
        const SizedBox(height: 12),
        _buildPolicyCard('Cancellation Policy', cancellationPolicy,
            highlight: true),
        const SizedBox(height: 12),
        _buildPolicyCard('House Rules', houseRules),
      ],
    );
  }

  Widget _buildPolicyCard(String title, String content, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: highlight
            ? Border.all(color: Colors.red.shade300)
            : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.red.shade700 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return FutureBuilder(
      future: _reviewService.getReviewsByPropertyId(widget.propertyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.currentUserId != null)
                  TextButton(
                    onPressed: () => _showReviewDialog(),
                    child: const Text('Add Review'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              const Text('No reviews yet'),
            ...reviews.map((review) => _buildReviewCard(review)),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(dynamic review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(review.userImage),
                radius: 20,
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          intl.DateFormat('MMM dd, yyyy').format(review.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.reviewText,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          if (review.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: DecorationImage(
                          image: NetworkImage(review.imageUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showReviewDialog({bool promptRating = false}) {
    int rating = 5;
    final reviewController = TextEditingController();
    List<picker.XFile> selectedImages = [];
    bool isUploading = false;
    bool isDialogOpen = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(promptRating ? 'Please rate your stay ⭐' : 'Add Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rating'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setDialogState(() => rating = index + 1);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedImages.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: FileImage(File(selectedImages[index].path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  color: Colors.black54,
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final picker.ImagePicker imagePicker = picker.ImagePicker();
                    final List<picker.XFile> images = await imagePicker.pickMultiImage();
                    if (images.isNotEmpty) {
                      setDialogState(() {
                        selectedImages.addAll(images);
                      });
                    }
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add Photos'),
                ),
                if (isUploading) 
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                reviewController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                setDialogState(() => isUploading = true);
                List<String> imageUrls = [];
                try {
                  // Upload all images in parallel
                  if (selectedImages.isNotEmpty) {
                    final uploadFutures = selectedImages.map((image) async {
                      final ref = storage.FirebaseStorage.instance
                          .ref()
                          .child('reviews/${widget.propertyId}/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
                      await ref.putFile(File(image.path));
                      return await ref.getDownloadURL();
                    });
                    imageUrls = await Future.wait(uploadFutures);
                  }
                  await _submitReview(
                    rating: rating,
                    reviewText: reviewController.text,
                    imageUrls: imageUrls,
                  );
                  reviewController.dispose();
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to upload images: $e')),
                    );
                  }
                  setDialogState(() => isUploading = false);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview({
    required int rating,
    required String reviewText,
    required List<String> imageUrls,
  }) async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit a review')),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'Guest';
      final userImage = userData?['image'] ?? 'https://ui-avatars.com/api/?name=Guest';

      await _reviewService.addReview(
        propertyId: widget.propertyId,
        userId: widget.currentUserId!,
        userName: userName,
        userImage: userImage,
        rating: rating,
        reviewText: reviewText,
        imageUrls: imageUrls,
      );
      if (mounted) {
        setState(() {}); // trigger rebuild to show reviews
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review')),
        );
      }
    }
  }

  // Similar properties feature removed.

  Widget _buildFixedBottomBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${property.pricePerNight.toStringAsFixed(0)}/night',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Including taxes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _handleBookNow,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBookNow() {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')),
      );
      return;
    }

    // Navigate to booking screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proceeding to booking...')),
    );
  }

  void _shareProperty() {
    share.Share.share(
      'Check this farmhouse on Farmigo: https://farmigo.in/property/${widget.propertyId}',
    );
  }
}
