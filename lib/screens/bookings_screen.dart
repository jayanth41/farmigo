//bookings screen
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:get/get.dart';
import '../controllers/bookings_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/no_data_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/booking_item.dart';


class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late BookingsController bookingsController;
  String _filterStatus = 'all'; // all, upcoming, completed, cancelled

  @override
  void initState() {
    super.initState();
    bookingsController = Get.put(BookingsController());
    bookingsController.fetchBookings(); // Ensure fresh data on load
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
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
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
                          return BookingItem(booking: booking);
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
          backgroundColor: active ? AppColors.primary : Colors.grey[100],
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