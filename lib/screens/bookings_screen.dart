import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../navigation/app_routes.dart';
import '../controllers/bookings_controller.dart';
// app_drawer removed from this secondary screen to keep back navigation consistent
import '../widgets/loading_widget.dart';
import '../theme/app_colors.dart';


class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late dynamic bookingsController;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    bookingsController = Get.put(BookingsController());
    bookingsController.fetchBookings();
  }

  List get filteredBookings {
    if (_filterStatus == 'all') {
      return bookingsController.bookings;
    }
    return bookingsController.bookings
        .where((booking) => booking['status'] == _filterStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Secondary screen: provide back button and consistent AppBar styling
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Bookings', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => bookingsController.fetchBookings(),
            tooltip: 'Refresh bookings',
          ),
        ],
      ),
      body: Obx(() {
        if (bookingsController.isLoading.value) {
          return const LoadingWidget();
        } else if (bookingsController.bookings.isEmpty) {
          // Centered empty state per design requirements
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 72, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(
                  'No bookings yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have no bookings at the moment',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                      } catch (_) {}
                    },
                    child: const Text('Explore Properties'),
                  ),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              // Filter Tabs (styled like the React buttons)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Row(
                    children: [
                      _filterButton('all', 'All'),
                      _filterButton('upcoming', 'Upcoming'),
                      _filterButton('completed', 'Completed'),
                      _filterButton('cancelled', 'Cancelled'),
                    ],
                  ),
                ),
              ),
              // Bookings List
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No $_filterStatus bookings',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return BookingItemCard(booking: booking);
                        },
                      ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _filterButton(String value, String label) {
    final bool active = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
          child: ElevatedButton(
        onPressed: () => setState(() => _filterStatus = value),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              active ? AppColors.primary : Colors.grey[100],
          foregroundColor: active ? Colors.white : Colors.grey[700],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: active ? 2 : 0,
        ),
        child: Text(label),
      ),
    );
  }
}

// NEW WIDGET FOR BOOKING CARD WITH DETAILS
class BookingItemCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingItemCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    // Enhanced booking card UI
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

  // Prefer the canonical keys used by the bookings API
  String imageUrl = booking['imageUrl'] ?? booking['image'] ?? booking['propertyImage'] ?? '';

    String formatDate(String? raw) {
      if (raw == null || raw.toString().trim().isEmpty) return '';
      try {
        final dt = DateTime.parse(raw);
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        return raw;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      height: 160,
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.home, size: 48, color: cs.onSurface.withOpacity(0.3)),
                    ),
                  )
                : Container(
                    height: 160,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.home, size: 48, color: cs.onSurface.withOpacity(0.3)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        booking['propertyName'] ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: cs.onSurface.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking['location'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-in', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7))),
                          const SizedBox(height: 4),
                          Text(formatDate(booking['checkIn']), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-out', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7))),
                          const SizedBox(height: 4),
                          Text(formatDate(booking['checkOut']), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (booking['totalPrice'] != null && (booking['totalPrice'] is num ? (booking['totalPrice'] as num) > 0 : booking['totalPrice'].toString().isNotEmpty))
                      Text(
                        '₹${booking['totalPrice'].toString()}',
                        style: theme.textTheme.titleSmall?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showBookingDetails(context, booking),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (booking['status'] == 'upcoming')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showCancelDialog(context, booking),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Cancel'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    switch (s) {
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDetails(
      BuildContext context, Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
    _buildDetailRow('Booking ID', booking['id']?.toString() ?? ''),
    _buildDetailRow('Property', booking['propertyName'] ?? ''),
    _buildDetailRow('Location', booking['location'] ?? ''),
    _buildDetailRow('Check-in', booking['checkIn'] ?? ''),
    _buildDetailRow('Check-out', booking['checkOut'] ?? ''),
    _buildDetailRow('Guests', booking['guests']?.toString() ?? ''),
    _buildDetailRow('Total Price', booking['totalPrice'] != null ? '₹${booking['totalPrice']}' : ''),
    _buildDetailRow('Status', booking['status']?.toString().toUpperCase() ?? ''),
              const SizedBox(height: 12),
              const Text(
                'Cancellation Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                'Free cancellation up to 7 days before check-in. After that, 50% refund applies.',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
      BuildContext context, Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking ID: ${booking['id']?.toString() ?? ''}'),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to cancel this booking?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Refund: ₹${((booking['totalPrice'] ?? 0) * 0.5).toStringAsFixed(0)} (50% of total)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () async {
              final bookingsController = Get.find<BookingsController>();
              final success = await bookingsController.cancelBooking(booking['id']);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Booking cancelled' : 'Failed to cancel booking'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}