import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car_booking.dart';
import 'invoice_screen.dart';

class CarRentalsScreen extends StatefulWidget {
  const CarRentalsScreen({super.key});

  @override
  State<CarRentalsScreen> createState() => _CarRentalsScreenState();
}

class _CarRentalsScreenState extends State<CarRentalsScreen> {
  late Future<List<DocumentSnapshot>> _carsListFuture;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _needsDriver = false;
  String? _selectedCarId;
  Map<String, dynamic>? _selectedCar;

  @override
  void initState() {
    super.initState();
    _carsListFuture = _loadCars();
  }

  Future<List<DocumentSnapshot>> _loadCars() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs;
    } catch (e) {
      debugPrint('Error loading cars: $e');
      return [];
    }
  }

  List<DateTime> _getBlockedDates(Map<String, dynamic> carData) {
    try {
      final blockedDates = carData['blockedDates'] as List<dynamic>?;
      if (blockedDates == null) return [];
      return blockedDates
          .map((date) => (date as Timestamp).toDate())
          .toList();
    } catch (e) {
      return [];
    }
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  double _calculatePrice(
    DateTime startDate,
    DateTime? endDate,
    Map<String, dynamic> carData,
    bool needsDriver,
  ) {
    double totalPrice = 0;
    final double pricePerDay = (carData['pricePerDay'] ?? 0).toDouble();
    final double pricePerHour = (carData['pricePerHour'] ?? 0).toDouble();
    final double weekendPrice = (carData['weekendPrice'] ?? pricePerDay).toDouble();
    final int minHours = (carData['minHours'] ?? 1) as int;
    final double driverCharge = (carData['driverHourlyCharge'] ?? 0).toDouble();

    if (endDate == null || startDate == endDate) {
      if (pricePerHour > 0) {
        totalPrice = minHours * pricePerHour;
        if (needsDriver) {
          totalPrice += minHours * driverCharge;
        }
      } else {
        totalPrice = pricePerDay;
        if (needsDriver) {
          totalPrice += driverCharge;
        }
      }
    } else {
      DateTime current = startDate;
      while (current.isBefore(endDate) || current == endDate) {
        if (_isWeekend(current)) {
          totalPrice += weekendPrice;
        } else {
          totalPrice += pricePerDay;
        }
        current = current.add(const Duration(days: 1));
      }

      if (needsDriver) {
        final days = endDate.difference(startDate).inDays + 1;
        totalPrice += days * driverCharge * 8;
      }
    }

    return totalPrice;
  }

  void _showCalendarPicker(Map<String, dynamic> carData) {
    final blockedDates = _getBlockedDates(carData);

    showDialog(
      context: context,
      builder: (context) => _CalendarPickerDialog(
        blockedDates: blockedDates,
        onDateSelected: (start, end) {
          setState(() {
            _selectedStartDate = start;
            _selectedEndDate = end;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _proceedToBooking() {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select booking dates')),
      );
      return;
    }

    if (_selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car')),
      );
      return;
    }

    final double pricePerDay = (_selectedCar!['pricePerDay'] ?? 0).toDouble();
    final double pricePerHour = (_selectedCar!['pricePerHour'] ?? 0).toDouble();
    final double weekendPrice = (_selectedCar!['weekendPrice'] ?? pricePerDay).toDouble();
    final int minHours = (_selectedCar!['minHours'] ?? 1) as int;
    final double driverCharge = (_selectedCar!['driverHourlyCharge'] ?? 0).toDouble();

    int weekdayTotal = 0;
    int weekendTotal = 0;
    int hourlyTotal = 0;
    int driverTotal = 0;
    int finalTotal = 0;

    if (_selectedEndDate == null || _selectedStartDate == _selectedEndDate) {
      // Same-day booking
      if (pricePerHour > 0) {
        hourlyTotal = (minHours * pricePerHour).toInt();
        if (_needsDriver) {
          driverTotal = (minHours * driverCharge).toInt();
        }
      } else {
        weekdayTotal = pricePerDay.toInt();
        if (_needsDriver) {
          driverTotal = driverCharge.toInt();
        }
      }
    } else {
      // Multi-day booking
      DateTime current = _selectedStartDate!;
      while (current.isBefore(_selectedEndDate!) || current == _selectedEndDate) {
        if (_isWeekend(current)) {
          weekendTotal += weekendPrice.toInt();
        } else {
          weekdayTotal += pricePerDay.toInt();
        }
        current = current.add(const Duration(days: 1));
      }

      if (_needsDriver) {
        final days = _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;
        driverTotal = (days * driverCharge * 8).toInt();
      }
    }

    finalTotal = weekdayTotal + weekendTotal + hourlyTotal + driverTotal;

    final booking = CarBooking(
      carId: _selectedCarId!,
      carName: _selectedCar!['carName'] ?? 'Unknown Car',
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      ownerId: _selectedCar!['ownerId'] ?? '',
      startDate: _selectedStartDate!,
      endDate: _selectedEndDate ?? _selectedStartDate!,
      hours: _selectedEndDate == null ? null : null,
      pricePerDay: pricePerDay.toInt(),
      weekendPrice: weekendPrice.toInt(),
      hourlyPrice: pricePerHour.toInt(),
      driverHourlyCharge: driverCharge.toInt(),
      driverRequested: _needsDriver,
      weekdayTotal: weekdayTotal,
      weekendTotal: weekendTotal,
      driverTotal: driverTotal,
      hourlyTotal: hourlyTotal,
      finalTotal: finalTotal,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceScreen(
          booking: booking,
          onConfirmPay: () {
            _saveBooking(booking);
          },
        ),
      ),
    );
  }

  Future<void> _saveBooking(CarBooking booking) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('car_bookings').doc().set(booking.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse & Book Cars'),
        elevation: 0,
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _carsListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final cars = snapshot.data ?? [];
          if (cars.isEmpty) {
            return const Center(
              child: Text('No cars available right now'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final carDoc = cars[index];
              final carData = carDoc.data() as Map<String, dynamic>;
              final isSelected = _selectedCarId == carDoc.id;

              return _CarListingCard(
                carData: carData,
                carDoc: carDoc,
                isSelected: isSelected,
                onSelect: () {
                  setState(() {
                    _selectedCarId = carDoc.id;
                    _selectedCar = carData;
                    _selectedStartDate = null;
                    _selectedEndDate = null;
                  });
                },
                onPickDates: () => _showCalendarPicker(carData),
                selectedDates: _selectedStartDate != null
                    ? '${_selectedStartDate!.toString().split(' ')[0]} - ${_selectedEndDate?.toString().split(' ')[0] ?? 'same day'}'
                    : 'Select dates',
                onNeedsDriverChanged: (value) {
                  setState(() => _needsDriver = value);
                },
                needsDriver: _needsDriver,
              );
            },
          );
        },
      ),
      bottomNavigationBar: _selectedStartDate != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedCar != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Price:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${_calculatePrice(_selectedStartDate!, _selectedEndDate, _selectedCar!, _needsDriver).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceedToBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _CarListingCard extends StatelessWidget {
  final Map<String, dynamic> carData;
  final DocumentSnapshot carDoc;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPickDates;
  final String selectedDates;
  final ValueChanged<bool> onNeedsDriverChanged;
  final bool needsDriver;

  const _CarListingCard({
    required this.carData,
    required this.carDoc,
    required this.isSelected,
    required this.onSelect,
    required this.onPickDates,
    required this.selectedDates,
    required this.onNeedsDriverChanged,
    required this.needsDriver,
  });

  @override
  Widget build(BuildContext context) {
    final photos = (carData['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [];
    final pricePerDay = carData['pricePerDay'] ?? 0;
    final pricePerHour = carData['pricePerHour'] ?? 0;
    final carName = carData['carName'] ?? 'Unknown Car';
    final carCategory = carData['carCategory'] ?? 'Car';
    final seats = carData['seats'] ?? 0;
    final driverAvailable = carData['driverAvailable'] ?? false;

    return GestureDetector(
      onTap: onSelect,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: Colors.green, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      photos[0],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.directions_car, size: 64),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    carCategory,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event_seat, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('$seats seats', style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 16),
                      if (driverAvailable) ...[
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        const Text('Driver available', style: TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹$pricePerDay/day',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (pricePerHour > 0)
                            Text(
                              '₹$pricePerHour/hour',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      if (isSelected)
                        ElevatedButton.icon(
                          onPressed: onPickDates,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Dates'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dates: $selectedDates',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          if (driverAvailable)
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Need Driver?',
                                  style: TextStyle(fontSize: 13)),
                              value: needsDriver,
                              onChanged: onNeedsDriverChanged,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarPickerDialog extends StatefulWidget {
  final List<DateTime> blockedDates;
  final Function(DateTime, DateTime?) onDateSelected;

  const _CalendarPickerDialog({
    required this.blockedDates,
    required this.onDateSelected,
  });

  @override
  State<_CalendarPickerDialog> createState() => _CalendarPickerDialogState();
}

class _CalendarPickerDialogState extends State<_CalendarPickerDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 59));
  }

  bool _isDateBlocked(DateTime date) {
    return widget.blockedDates.any(
      (blockedDate) =>
          blockedDate.year == date.year &&
          blockedDate.month == date.month &&
          blockedDate.day == date.day,
    );
  }

  bool _isDateInRange(DateTime date, DateTime start, DateTime? end) {
    if (end == null) return date == start;
    return (date == start || date.isAfter(start)) &&
        (date == end || date.isBefore(end));
  }

  bool _isRangeContainsBlocked(DateTime start, DateTime end) {
    DateTime current = start;
    while (current.isBefore(end) || current == end) {
      if (_isDateBlocked(current)) return true;
      current = current.add(const Duration(days: 1));
    }
    return false;
  }

  void _selectDate(DateTime date) {
    if (_isDateBlocked(date)) return;

    setState(() {
      if (_selectedStart == null) {
        _selectedStart = date;
        _selectedEnd = null;
      } else if (_selectedEnd == null) {
        if (date.isBefore(_selectedStart!)) {
          _selectedStart = date;
        } else if (date == _selectedStart) {
          _selectedStart = null;
        } else {
          if (_isRangeContainsBlocked(_selectedStart!, date)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This car is unavailable for one or more selected dates.',
                ),
              ),
            );
            return;
          }
          _selectedEnd = date;
        }
      } else {
        _selectedStart = date;
        _selectedEnd = null;
      }
    });
  }

  void _confirmSelection() {
    if (_selectedStart != null) {
      Navigator.pop(context);
      widget.onDateSelected(_selectedStart!, _selectedEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = <Widget>[];
    DateTime current = _startDate;

    final dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final day in dayHeaders) {
      days.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }

    int firstDayOffset = _startDate.weekday - 1;
    for (int i = 0; i < firstDayOffset; i++) {
      days.add(const SizedBox());
    }

    while (current.isBefore(_endDate) || current == _endDate) {
      final isBlocked = _isDateBlocked(current);
      final isInRange = _isDateInRange(current, _selectedStart ?? current, _selectedEnd);
      final isStart = current == _selectedStart;

      days.add(
        GestureDetector(
          onTap: isBlocked ? null : () => _selectDate(current),
          child: Container(
            decoration: BoxDecoration(
              color: isBlocked
                  ? Colors.red[200]
                  : isInRange
                      ? Colors.blue[200]
                      : Colors.transparent,
              border: isStart ? Border.all(color: Colors.green, width: 2) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              '${current.day}',
              style: TextStyle(
                fontSize: 12,
                color: isBlocked ? Colors.red[900] : Colors.black,
                fontWeight: isStart ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );

      current = current.add(const Duration(days: 1));
    }

    return AlertDialog(
      title: const Text('Select Booking Dates'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Container(width: 16, height: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('Selected', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 16, height: 16, color: Colors.blue[200]),
                    const SizedBox(width: 4),
                    const Text('Range', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 16, height: 16, color: Colors.red[200]),
                    const SizedBox(width: 4),
                    const Text('Blocked', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: days,
            ),
            const SizedBox(height: 16),
            if (_selectedStart != null)
              Text(
                _selectedEnd != null
                    ? '${_selectedStart!.toString().split(' ')[0]} - ${_selectedEnd!.toString().split(' ')[0]}'
                    : _selectedStart!.toString().split(' ')[0],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedStart != null ? _confirmSelection : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
