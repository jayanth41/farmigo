import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF2E8B57),
                  borderRadius: BorderRadius.circular(22),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black87,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(text: 'Revenue'),
                  Tab(text: 'Properties'),
                  Tab(text: 'Categories'),
                  Tab(text: 'Occupancy'),
                ],
              ),
            ),
          ),
        ),
      ),
        body: userId == null
          ? const Center(child: Text('User not authenticated'))
          : TabBarView(
              controller: _tabController,
              children: [
                _RevenueTab(userId: userId),
                _PropertiesTab(userId: userId),
                _CategoriesTab(userId: userId),
                _OccupancyTab(userId: userId),
              ],
            ),
    );
  }
}

// ============ REVENUE TAB ============
class _RevenueTab extends StatelessWidget {
  final String userId;
  const _RevenueTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .asyncExpand((propSnap) {
        final pids = propSnap.docs.map((d) => d.id).toList();
        if (pids.isEmpty) {
          return const Stream.empty();
        }
        return FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'confirmed')
            .where('propertyId', whereIn: pids)
            .snapshots();
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter on client side to only confirmed bookings
        final bookings = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((booking) => booking['status'] == 'confirmed')
            .toList();

        // Calculate totals
        final totalRevenue = bookings.fold<double>(
          0,
          (sum, booking) => sum + (booking['totalAmount']?.toDouble() ?? 0),
        );
        final totalBookings = bookings.length;

        // Build monthly trend (Aug 2025 → Feb 2026)
        final monthlyData = _calculateMonthlyTrend(bookings);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up,
                      value: r'$' + totalRevenue.toStringAsFixed(0),
                      label: 'Total Revenue',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_today,
                      value: totalBookings.toString(),
                      label: 'Total Bookings',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Monthly Trend Chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Trend',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            // Green line: Revenue
                            LineChartBarData(
                              spots: monthlyData.asMap().entries.map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  e.value['revenue'] as double,
                                );
                              }).toList(),
                              isCurved: true,
                              color: const Color(0xFF5FBF88),
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: false),
                            ),
                            // Blue line: Bookings
                            LineChartBarData(
                              spots: monthlyData.asMap().entries.map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  (e.value['bookings'] as int).toDouble() * 1000, // Scale for visibility
                                );
                              }).toList(),
                              isCurved: true,
                              color: Colors.blue,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const months = [
                                    'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                                    'Jan', 'Feb'
                                  ];
                                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                                    return Text(months[value.toInt()]);
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text('\$${(value / 1000).toStringAsFixed(0)}k');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _LegendItem(color: const Color(0xFF5FBF88), label: 'Revenue'),
                        const SizedBox(width: 16),
                        _LegendItem(color: Colors.blue, label: 'Bookings (×1000)'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _calculateMonthlyTrend(List<Map<String, dynamic>> bookings) {
    // Initialize 7 months (Aug 2025 - Feb 2026)
    final months = List.generate(7, (i) {
      return {'revenue': 0.0, 'bookings': 0};
    });

    for (final booking in bookings) {
      final checkIn = booking['checkIn'] as Timestamp?;
      if (checkIn == null) continue;

      final date = checkIn.toDate();
      final month = date.month;
      final year = date.year;

      // Map to month index (Aug=0, Sep=1, ..., Feb=6)
      int monthIndex = -1;
      if (year == 2025 && month >= 8) {
        monthIndex = month - 8;
      } else if (year == 2026 && month <= 2) {
        monthIndex = month + 4;
      }

      if (monthIndex >= 0 && monthIndex < 7) {
        months[monthIndex]['revenue'] = (months[monthIndex]['revenue'] as double) +
            (booking['totalAmount']?.toDouble() ?? 0);
        months[monthIndex]['bookings'] = (months[monthIndex]['bookings'] as int) + 1;
      }
    }

    return months;
  }
}

// ============ PROPERTIES TAB ============
class _PropertiesTab extends StatefulWidget {
  final String userId;
  const _PropertiesTab({required this.userId});

  @override
  State<_PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<_PropertiesTab> {
  String? _selectedProperty;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: widget.userId)
          .snapshots()
          .asyncExpand((propSnap) {
        final pids = propSnap.docs.map((d) => d.id).toList();
        if (pids.isEmpty) {
          return const Stream.empty();
        }
        return FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'confirmed')
            .where('propertyId', whereIn: pids)
            .snapshots();
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter on client side to only confirmed bookings
        final bookings = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((booking) => booking['status'] == 'confirmed')
            .toList();

        // Group by property
        final propertyData = _groupByProperty(bookings);
        final sortedProperties = propertyData.keys.toList()..sort();

        // Calculate chart data
        final chartData = propertyData.entries.map((e) {
          return {
            'property': e.key,
            'bookings': e.value['count'] as int,
            'revenue': e.value['revenue'] as double,
          };
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Properties Analytics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final data = chartData[groupIndex];
                                final label = rodIndex == 0 ? 'Bookings' : 'Revenue';
                                final value = rodIndex == 0
                                    ? (data['bookings'] as int).toString()
                                    : r'$' + (data['revenue'] as double).toStringAsFixed(0);
                                return BarTooltipItem(
                                  '$label\n$value',
                                  const TextStyle(color: Colors.black, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        chartData[value.toInt()]['property'].toString(),
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString());
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: chartData.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: (e.value['bookings'] as int).toDouble(),
                                  color: Colors.blue,
                                  width: 10,
                                ),
                                BarChartRodData(
                                  toY: (e.value['revenue'] as double) / 1000,
                                  color: const Color(0xFF5FBF88),
                                  width: 10,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _LegendItem(color: Colors.blue, label: 'Bookings'),
                        const SizedBox(width: 16),
                        _LegendItem(color: const Color(0xFF5FBF88), label: 'Revenue (÷1000)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Property Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...sortedProperties.map((property) {
                final data = propertyData[property]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['count']} bookings • \$${(data['revenue'] as double).toStringAsFixed(0)} revenue',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Map<String, Map<String, dynamic>> _groupByProperty(List<Map<String, dynamic>> bookings) {
    final grouped = <String, Map<String, dynamic>>{};
    for (final booking in bookings) {
      final propertyName = booking['propertyName'] as String? ?? 'Unknown';
      if (!grouped.containsKey(propertyName)) {
        grouped[propertyName] = {'count': 0, 'revenue': 0.0};
      }
      grouped[propertyName]!['count'] = (grouped[propertyName]!['count'] as int) + 1;
      grouped[propertyName]!['revenue'] =
          (grouped[propertyName]!['revenue'] as double) + (booking['totalAmount']?.toDouble() ?? 0);
    }
    return grouped;
  }
}

// ============ CATEGORIES TAB ============
class _CategoriesTab extends StatelessWidget {
  final String userId;
  const _CategoriesTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .asyncExpand((propSnap) {
        final pids = propSnap.docs.map((d) => d.id).toList();
        if (pids.isEmpty) {
          return const Stream.empty();
        }
        return FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'confirmed')
            .where('propertyId', whereIn: pids)
            .snapshots();
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter on client side to only confirmed bookings
        final bookings = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((booking) => booking['status'] == 'confirmed')
            .toList();

        // Group by category
        final categoryData = _groupByCategory(bookings);
        final total = categoryData.values.fold<int>(0, (sum, count) => sum + count);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pie Chart
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bookings by Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: _buildPieChart(categoryData, total),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category Breakdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category Breakdown',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...categoryData.entries.map((e) {
                            final percentage = ((e.value / total) * 100).toStringAsFixed(1);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _CategoryRow(
                                label: e.key,
                                percent: '$percentage%',
                                color: _getCategoryColor(e.key),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, int> _groupByCategory(List<Map<String, dynamic>> bookings) {
    final grouped = <String, int>{};
    for (final booking in bookings) {
      final category = booking['category'] as String? ?? 'Other';
      grouped[category] = (grouped[category] ?? 0) + 1;
    }
    return grouped;
  }

  Color _getCategoryColor(String category) {
    const colors = {
      'Farmhouse': Color(0xFF5FBF88),
      'Villa': Colors.blue,
      'Hotel': Colors.purple,
      'Resort': Colors.orange,
    };
    return colors[category] ?? Colors.grey;
  }

  Widget _buildPieChart(Map<String, int> categoryData, int total) {
    final sections = categoryData.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
        color: _getCategoryColor(e.key),
        radius: 90,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 0,
      ),
    );
  }
}

// ============ OCCUPANCY TAB ============
class _OccupancyTab extends StatelessWidget {
  final String userId;
  const _OccupancyTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .asyncExpand((propSnap) {
        final pids = propSnap.docs.map((d) => d.id).toList();
        if (pids.isEmpty) {
          return const Stream.empty();
        }
        return FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'confirmed')
            .where('propertyId', whereIn: pids)
            .snapshots();
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter on client side to only confirmed bookings
        final bookings = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((booking) => booking['status'] == 'confirmed')
            .toList();

        // Calculate weekly occupancy
        final weeklyOccupancy = _calculateWeeklyOccupancy(bookings);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Occupancy',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final occupancy = weeklyOccupancy[groupIndex];
                                return BarTooltipItem(
                                  '${occupancy.toStringAsFixed(1)}%',
                                  const TextStyle(color: Colors.black, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                                    return Text(days[value.toInt()]);
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}%');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: weeklyOccupancy[index],
                                  color: const Color(0xFF5FBF88),
                                  width: 14,
                                ),
                              ],
                            );
                          }),
                          maxY: 100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<double> _calculateWeeklyOccupancy(List<Map<String, dynamic>> bookings) {
    // Initialize occupancy for each day of week (0=Mon, 6=Sun)
    final dayOccupancy = List<int>.filled(7, 0);

    for (final booking in bookings) {
      final checkIn = booking['checkIn'] as Timestamp?;
      final checkOut = booking['checkOut'] as Timestamp?;

      if (checkIn == null || checkOut == null) continue;

      final checkInDate = checkIn.toDate();
      final checkOutDate = checkOut.toDate();

      // Count days for this booking
      var currentDate = checkInDate;
      while (currentDate.isBefore(checkOutDate)) {
        final dayOfWeek = (currentDate.weekday % 7); // 0=Mon, 6=Sun
        dayOccupancy[dayOfWeek]++;
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    // Normalize to 0-100% (assuming 5 weeks in range)
    const maxBookingsPerDay = 5; // Normalize to 5 concurrent bookings = 100%
    return dayOccupancy.map((count) => (count / maxBookingsPerDay * 100).clamp(0, 100).toDouble()).toList();
  }
}

// ============ HELPER WIDGETS ============
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;

  const _CategoryRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(percent, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
