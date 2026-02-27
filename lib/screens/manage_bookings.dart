
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  String _activeTab = 'all';
  String _timeFilter = 'all_properties'; // all_properties | this_week | this_month | custom
  DateTimeRange? _customRange;
  bool _showCalendar = false;
  // ignore: unused_field
  DateTime _calendarMonth = DateTime.now();
  List<Map<String, dynamic>> _allBookings = [];

  // --- helpers to map Firestore docs ---
  Map<String, dynamic> _mapBooking(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      'property': d['propertyName'] ?? 'Property',
      'type': d['propertyType'] ?? 'Farmhouse',
      'guest': d['guestName'] ?? 'Guest',
      'email': d['guestEmail'] ?? '',
      'phone': d['guestPhone'] ?? '',
      'dateRange': d['dateRange'] ?? '',
      'nightsGuests': d['nightsGuests'] ?? '',
      'total': d['total']?.toString() ?? '',
      'status': d['status'] ?? 'pending',
      // IMPORTANT: store start/end as Timestamp in Firestore
      'startDate': (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'endDate': (d['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    };
  }

  // --- update status in Firestore ---
  Future<void> _confirmBooking(String id) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(id)
        .update({'status': 'confirmed'});
    await _sendGuestNotification(id, 'confirmed');
  }

  Future<void> _declineBooking(String id) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(id)
        .update({'status': 'cancelled'});
    await _sendGuestNotification(id, 'cancelled');
  }

  Future<void> _sendGuestNotification(String bookingId, String status) async {
    try {
      // Get the booking document to retrieve guestFcmToken
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
      
      if (!bookingDoc.exists) {
        debugPrint('Booking $bookingId not found');
        return;
      }
      
      final guestFcmToken = bookingDoc.data()?['guestFcmToken'] as String?;
      
      if (guestFcmToken == null || guestFcmToken.isEmpty) {
        debugPrint('No FCM token for booking $bookingId');
        return;
      }
      
      // Call a Firestore Cloud Function by triggering it through a collection write
      // or by creating an HTTP callable endpoint. For now, we'll log the notification intent.
      // In production, implement this via:
      // 1. Firebase Cloud Functions HTTP endpoint
      // 2. A queue collection that processes notifications
      // 3. Or a native platform channel to iOS/Android FCM APIs
      
      debugPrint('Guest notification queued for bookingId=$bookingId, status=$status, token=$guestFcmToken');
      
      // Optional: Write to a notifications queue for server-side processing
      await FirebaseFirestore.instance.collection('notification_queue').add({
        'guestFcmToken': guestFcmToken,
        'bookingId': bookingId,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });
    } catch (e) {
      debugPrint('Error queuing guest notification: $e');
    }
  }

  Future<void> _exportBookingsToCsv(List<Map<String, dynamic>> bookings) async {
    final buffer = StringBuffer();
    buffer.writeln('bookingId,property,guest,status,startDate,endDate,total');
    for (final b in bookings) {
      buffer.writeln([
        b['id'],
        b['property'],
        b['guest'],
        b['status'],
        (b['startDate'] as DateTime).toIso8601String(),
        (b['endDate'] as DateTime).toIso8601String(),
        b['total'],
      ].join(','));
    }
    final file = File('${Directory.systemTemp.path}/bookings_export.csv');
    await file.writeAsString(buffer.toString());
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Export Ready'),
          content: Text('Saved to:\n${file.path}\nYou can open this in Excel.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> list) {
    // ---- STATUS FILTER ----
    List<Map<String, dynamic>> filtered = _activeTab == 'all'
        ? List.from(list)
        : list.where((b) => b['status'] == _activeTab).toList();

    final now = DateTime.now();

    // ---- TIME FILTER ----
    switch (_timeFilter) {
      case 'this_week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return filtered.where((b) {
          final s = b['startDate'] as DateTime;
          return s.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              s.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();

      case 'this_month':
        return filtered.where((b) {
          final s = b['startDate'] as DateTime;
          return s.year == now.year && s.month == now.month;
        }).toList();

      case 'custom':
        if (_customRange == null) return filtered;
        return filtered.where((b) {
          final s = b['startDate'] as DateTime;
          return s.isAfter(_customRange!.start.subtract(const Duration(days: 1))) &&
              s.isBefore(_customRange!.end.add(const Duration(days: 1)));
        }).toList();

      case 'all_properties':
      default:
        return filtered;
    }
  }

  Widget _buildCalendarGrid(List<Map<String, dynamic>> allBookings) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    
    // Get first day of month
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final weekdayOfFirst = firstDay.weekday; // 1=Monday, 7=Sunday
    
    // Build bookings map by date (YYYY-MM-DD)
    Map<String, List<Map<String, dynamic>>> bookingsByDate = {};
    for (final booking in allBookings) {
      final startDate = booking['startDate'] as DateTime;
      final dateKey = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      bookingsByDate.putIfAbsent(dateKey, () => []).add(booking);
    }
    
    // Generate day cells
    List<Widget> dayWidgets = [];
    
    // Weekday headers
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final day in weekdays) {
      dayWidgets.add(
        Container(
          alignment: Alignment.center,
          child: Text(day, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B))),
        ),
      );
    }
    
    // Empty cells before first day
    for (int i = 1; i < weekdayOfFirst; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    
    // Days of month
    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final hasBooking = bookingsByDate.containsKey(dateKey);
      
      dayWidgets.add(
        GestureDetector(
          onTap: hasBooking
              ? () => _showDayBookingsSheet(context, day, month, year, bookingsByDate[dateKey]!)
              : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text('$day', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (hasBooking)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Month/Year header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_getMonthName(month)} $year',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () => setState(() {
                        if (month > 1) {
                          _calendarMonth = DateTime(year, month - 1);
                        }
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: () => setState(() {
                        if (month < 12) {
                          _calendarMonth = DateTime(year, month + 1);
                        }
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Calendar grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: dayWidgets,
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showDayBookingsSheet(BuildContext context, int day, int month, int year, List<Map<String, dynamic>> dayBookings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '$day ${_getMonthName(month)} $year',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: dayBookings.length,
                  itemBuilder: (context, index) {
                    final booking = dayBookings[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['property'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${booking['status']}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            booking['total'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: Color(0xFF15803D),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showCalendar ? Icons.list_alt : Icons.calendar_month, color: Colors.black87),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black87),
            onPressed: () => _exportBookingsToCsv(_allBookings),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading bookings: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No Bookings Yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your bookings will appear here once guests book your properties',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Map Firestore docs to list
            final allDocs = snapshot.data!.docs.map(_mapBooking).toList();
            // Filter by owner (both with ownerId field AND properties owned by this owner)
            // For now, show all bookings since data structure may vary
            final myBookings = allDocs;
            // Update state variable for export button
            _allBookings = myBookings;
            final bookings = _applyFilters(myBookings);

            final total = bookings.length;
            final confirmed = bookings.where((b) => b['status'] == 'confirmed').length;
            final pending = bookings.where((b) => b['status'] == 'pending').length;
            final completed = bookings.where((b) => b['status'] == 'completed').length;
            final cancelled = bookings.where((b) => b['status'] == 'cancelled').length;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Bookings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manage all your property bookings',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),

                    if (_showCalendar) ...[
                      _buildCalendarGrid(myBookings),
                      const SizedBox(height: 16),
                    ],

                    // --- STATS (2x2 layout like your screenshot) ---
                    Column(
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: _StatCard(
                                title: 'Total Bookings',
                                value: '$total',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: _StatCard(
                                title: 'Confirmed',
                                value: '$confirmed',
                                color: const Color(0xFF16A34A),
                                isHighlight: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Flexible(
                              child: _StatCard(
                                title: 'Pending',
                                value: '$pending',
                                color: const Color(0xFFF59E0B),
                                isHighlight: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: _StatCard(
                                title: 'Completed',
                                value: '$completed',
                                color: const Color(0xFF2563EB),
                                isHighlight: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- SEARCH + FILTER DROPDOWN ---
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search bookings...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _timeFilter,
                            icon: const Icon(Icons.filter_list, color: Color(0xFF16A34A)),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            items: const [
                              DropdownMenuItem(value: 'all_properties', child: Text('All properties')),
                              DropdownMenuItem(value: 'this_week', child: Text('This week')),
                              DropdownMenuItem(value: 'this_month', child: Text('This month')),
                              DropdownMenuItem(value: 'custom', child: Text('Custom range')),
                            ],
                            onChanged: (v) async {
                              if (v == null) return;
                              if (v == 'custom') {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2027),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _customRange = picked;
                                    _timeFilter = 'custom';
                                  });
                                }
                              } else {
                                setState(() => _timeFilter = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- STATUS TABS WITH COUNTS ---
                    SizedBox(
                      height: 44,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _StatusTab(label: 'All (${bookings.length})', active: _activeTab == 'all', onTap: () => setState(() => _activeTab = 'all')),
                            _StatusTab(label: 'Pending ($pending)', active: _activeTab == 'pending', onTap: () => setState(() => _activeTab = 'pending')),
                            _StatusTab(label: 'Confirmed ($confirmed)', active: _activeTab == 'confirmed', onTap: () => setState(() => _activeTab = 'confirmed')),
                            _StatusTab(label: 'Completed ($completed)', active: _activeTab == 'completed', onTap: () => setState(() => _activeTab = 'completed')),
                            _StatusTab(label: 'Cancelled ($cancelled)', active: _activeTab == 'cancelled', onTap: () => setState(() => _activeTab = 'cancelled')),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- BOOKING CARDS ---
                    ...List.generate(bookings.length, (index) {
                      final b = bookings[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BookingCard(
                            property: b['property'],
                            type: b['type'],
                            bookingId: b['id'],
                            guest: b['guest'],
                            email: b['email'],
                            phone: b['phone'],
                            dateRange: b['dateRange'],
                            nightsGuests: b['nightsGuests'],
                            total: b['total'],
                            status: b['status'],
                            onConfirm: () => _confirmBooking(b['id']),
                            onDecline: () => _declineBooking(b['id']),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===================== UI WIDGETS (unchanged) =====================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isHighlight;

  const _StatCard({required this.title, required this.value, required this.color, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: isHighlight ? null : Colors.white,
        gradient: isHighlight
            ? LinearGradient(colors: [color, color.withOpacity(0.85)])
            : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlight ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isHighlight ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StatusTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF16A34A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8)],
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : const Color.fromARGB(255, 41, 70, 92), fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String property;
  final String type;
  final String bookingId;
  final String guest;
  final String email;
  final String phone;
  final String dateRange;
  final String nightsGuests;
  final String total;
  final String status;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const _BookingCard({required this.property, required this.type, required this.bookingId, required this.guest, required this.email, required this.phone, required this.dateRange, required this.nightsGuests, required this.total, required this.status, required this.onConfirm, required this.onDecline});

  Color _statusColor() {
    switch (status) {
      case 'confirmed': return const Color(0xFF16A34A);
      case 'pending': return const Color(0xFFF59E0B);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return const Color.fromARGB(255, 41, 70, 92);
    }
  }

  String _statusLabel() => status;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10)]),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(property, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))) ,
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _statusColor().withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Row(children: [Icon(Icons.check_circle, size: 12, color: _statusColor()), const SizedBox(width: 4), Text(_statusLabel(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor()))])),
        ]),
        const SizedBox(height: 6),
        Text('Booking ID: $bookingId', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.person, size: 18, color: Color(0xFF16A34A)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(guest, style: const TextStyle(fontWeight: FontWeight.w700)), Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))), Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]))]),
            const SizedBox(height: 10),
            Row(children: [const Icon(Icons.calendar_today, size: 16, color: Color(0xFF16A34A)), const SizedBox(width: 8), Expanded(child: Text(dateRange, style: const TextStyle(fontSize: 12)))]),
            const SizedBox(height: 6),
            Text(nightsGuests, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 12),
        if (status == 'pending') Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: onConfirm, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: const Icon(Icons.check, size: 16), label: const Text('Confirm'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: onDecline, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: const BorderSide(color: Color(0xFFEF4444))), icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)), label: const Text('Decline', style: TextStyle(color: Color(0xFFEF4444))))),
        ]),
      ]),
    );
  }
}
