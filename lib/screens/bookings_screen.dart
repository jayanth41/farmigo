import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bookings_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/no_data_widget.dart';
import '../widgets/loading_widget.dart';

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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5016),
        title: const Text('My Bookings'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => bookingsController.fetchBookings(),
            tooltip: 'Refresh bookings',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (bookingsController.isLoading.value) {
          return const LoadingWidget();
        } else if (bookingsController.bookings.isEmpty) {
          return const NoDataWidget(message: 'No bookings found.');
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
              active ? const Color(0xFF2D5016) : Colors.grey[100],
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking['propertyName'] ?? 'Property',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking['location'] ?? 'Unknown location',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Check-in & Check-out dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Check-in',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        booking['checkInDate'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Check-out',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        booking['checkOutDate'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              '₹${booking['totalPrice']?.toString() ?? '0'} Total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    onPressed: () {
                      _showBookingDetails(context, booking);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2D5016)),
                      foregroundColor: const Color(0xFF2D5016),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (booking['status'] == 'upcoming')
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Cancel'),
                      onPressed: () {
                        _showCancelDialog(context, booking);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
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
              _buildDetailRow('Booking ID', booking['id'] ?? 'N/A'),
              _buildDetailRow(
                  'Property', booking['propertyName'] ?? 'N/A'),
              _buildDetailRow('Location', booking['location'] ?? 'N/A'),
              _buildDetailRow(
                  'Check-in', booking['checkInDate'] ?? 'N/A'),
              _buildDetailRow(
                  'Check-out', booking['checkOutDate'] ?? 'N/A'),
              _buildDetailRow('Guests',
                  booking['guests']?.toString() ?? 'N/A'),
              _buildDetailRow('Total Price',
                  '₹${booking['totalPrice'] ?? 0}'),
              _buildDetailRow('Status',
                  booking['status']?.toString().toUpperCase() ?? 'N/A'),
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
            Text('Booking ID: ${booking['id'] ?? 'N/A'}'),
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Booking cancelled successfully. Refund initiated.'),
                  duration: Duration(seconds: 2),
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