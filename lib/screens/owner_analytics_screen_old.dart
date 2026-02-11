import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
      body: TabBarView(
        controller: _tabController,
        children: [
          const _RevenueTab(),
          _PropertiesTab(),
          const _CategoriesTab(),
          const _OccupancyTab(),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Pie Chart
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
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 0,
                            sections: [
                              PieChartSectionData(
                                value: 45,
                                title: 'Farmhouses: 45%',
                                color: const Color(0xFF5FBF88),
                                radius: 90,
                                titleStyle: const TextStyle(fontSize: 12, color: Colors.black),
                              ),
                              PieChartSectionData(
                                value: 30,
                                title: 'Villas: 30%',
                                color: Colors.blue,
                                radius: 90,
                                titleStyle: const TextStyle(fontSize: 12, color: Colors.black),
                              ),
                              PieChartSectionData(
                                value: 15,
                                title: 'Hotels: 15%',
                                color: Colors.purple,
                                radius: 90,
                                titleStyle: const TextStyle(fontSize: 12, color: Colors.black),
                              ),
                              PieChartSectionData(
                                value: 10,
                                title: 'Others: 10%',
                                color: Colors.orange,
                                radius: 90,
                                titleStyle: const TextStyle(fontSize: 12, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Right: Category Breakdown
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
                      _CategoryRow(color: const Color(0xFF5FBF88), label: 'Farmhouses', percent: '45%'),
                      const SizedBox(height: 8),
                      _CategoryRow(color: Colors.blue, label: 'Villas', percent: '30%'),
                      const SizedBox(height: 8),
                      _CategoryRow(color: Colors.purple, label: 'Hotels', percent: '15%'),
                      const SizedBox(height: 8),
                      _CategoryRow(color: Colors.orange, label: 'Others', percent: '10%'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Reuse the same bottom section as Revenue/Properties tabs
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Top Performing Property',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text('Beach Villa', style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Bookings: 36', style: TextStyle(color: Colors.white)),
                      Text('Revenue: \$16,200', style: TextStyle(color: Colors.white)),
                      Text('Avg Rating: 4.9 ⭐', style: TextStyle(color: Colors.white)),
                      Text('Occupancy: 92%', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _RevenueTab._quickStat('Avg Booking Value', '\$338', Colors.green),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Avg Stay Duration', '3.2 nights', Colors.blue),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Return Customer Rate', '28%', Colors.purple),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Cancellation Rate', '5.2%', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;
  const _CategoryRow({required this.color, required this.label, required this.percent});

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

class _RevenueTab extends StatelessWidget {
  const _RevenueTab();

  Widget _statCard({required IconData icon, required String value, required String label, String? sub}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14,
                  backgroundColor: const Color(0xFFEFF8F2),
                  child: Icon(icon, size: 16, color: const Color(0xFF2E8B57)),
                ),
                const Spacer(),
                if (sub != null)
                  Text(
                    sub,
                    style: const TextStyle(color: Color(0xFF2E8B57), fontSize: 9, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              _statCard(
                icon: Icons.attach_money,
                value: '\$14,200',
                label: 'Total Revenue',
                sub: '+18.2%',
              ),
              _statCard(
                icon: Icons.people_outline,
                value: '42',
                label: 'Total Bookings',
                sub: '+12.5%',
              ),
              _statCard(
                icon: Icons.home_outlined,
                value: '84%',
                label: 'Occupancy Rate',
                sub: '+5.3%',
              ),
              _statCard(
                icon: Icons.star_outline,
                value: '4.8',
                label: 'Avg Rating',
                sub: '+0.2',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revenue & Bookings Trend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Legend
                    Row(
                      children: const [
                        Icon(Icons.circle, size: 10, color: Color(0xFF2E8B57)),
                        SizedBox(width: 6),
                        Text('Revenue', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 16),
                        Icon(Icons.circle, size: 10, color: Colors.blue),
                        SizedBox(width: 6),
                        Text('Bookings', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 8,
                            ),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const months = ['Aug','Sep','Oct','Nov','Dec','Jan','Feb'];
                                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                                    return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (value, meta) {
                                  return Text('\$${(value/1000).round()}k', style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              color: const Color(0xFF2E8B57),
                              spots: [
                                FlSpot(0, 8200),
                                FlSpot(1, 9500),
                                FlSpot(2, 11200),
                                FlSpot(3, 10800),
                                FlSpot(4, 13500),
                                FlSpot(5, 12200),
                                FlSpot(6, 14500),
                              ],
                              isCurved: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: false),
                            ),
                            LineChartBarData(
                              color: Colors.blue,
                              spots: [
                                FlSpot(0, 25),
                                FlSpot(1, 28),
                                FlSpot(2, 32),
                                FlSpot(3, 30),
                                FlSpot(4, 38),
                                FlSpot(5, 34),
                                FlSpot(6, 41),
                              ],
                              isCurved: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Top Performing Property',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text('Beach Villa', style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Bookings: 36', style: TextStyle(color: Colors.white)),
                      Text('Revenue: \$16,200', style: TextStyle(color: Colors.white)),
                      Text('Avg Rating: 4.9 ⭐', style: TextStyle(color: Colors.white)),
                      Text('Occupancy: 92%', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _quickStat('Avg Booking Value', '\$338', Colors.green),
                    const SizedBox(height: 8),
                    _quickStat('Avg Stay Duration', '3.2 nights', Colors.blue),
                    const SizedBox(height: 8),
                    _quickStat('Return Customer Rate', '28%', Colors.purple),
                    const SizedBox(height: 8),
                    _quickStat('Cancellation Rate', '5.2%', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _quickStat(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _OccupancyTab extends StatelessWidget {
  const _OccupancyTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Occupancy Rate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: true),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 75, color: Colors.deepPurpleAccent, width: 16)]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 68, color: Colors.deepPurpleAccent, width: 16)]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 82, color: Colors.deepPurpleAccent, width: 16)]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 78, color: Colors.deepPurpleAccent, width: 16)]),
                        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 95, color: Colors.deepPurpleAccent, width: 16)]),
                        BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 99, color: Colors.deepPurpleAccent, width: 16)]),
                        BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 92, color: Colors.deepPurpleAccent, width: 16)]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.square, size: 10, color: Colors.deepPurpleAccent),
                    SizedBox(width: 6),
                    Text('Occupancy Rate (%)', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bottom section reused
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Top Performing Property',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text('Beach Villa', style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Bookings: 36', style: TextStyle(color: Colors.white)),
                      Text('Revenue: \$16,200', style: TextStyle(color: Colors.white)),
                      Text('Avg Rating: 4.9 ⭐', style: TextStyle(color: Colors.white)),
                      Text('Occupancy: 92%', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _RevenueTab._quickStat('Avg Booking Value', r'$338', Colors.green),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Avg Stay Duration', '3.2 nights', Colors.blue),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Return Customer Rate', '28%', Colors.purple),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Cancellation Rate', '5.2%', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: const TextStyle(fontSize: 18)),
    );
  }
}
class _PropertiesTab extends StatelessWidget {
  const _PropertiesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Performance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 18000,
                      barTouchData: BarTouchData(enabled: true),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const names = ['Luxury', 'Beach', 'Cottage', 'Mountain', 'Bungalow'];
                              if (value.toInt() >= 0 && value.toInt() < names.length) {
                                return Text(names[value.toInt()], style: TextStyle(fontSize: 10));
                              }
                              return SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(), style: TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text('\$${(value/1000).round()}k', style: TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        // Luxury Farmhouse
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(toY: 40, color: Colors.blue, width: 10),
                          BarChartRodData(toY: 10000, color: Color(0xFF2E8B57), width: 10),
                        ]),
                        // Beach Villa
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(toY: 35, color: Colors.blue, width: 10),
                          BarChartRodData(toY: 16000, color: Color(0xFF2E8B57), width: 10),
                        ]),
                        // Cottage
                        BarChartGroupData(x: 2, barRods: [
                          BarChartRodData(toY: 50, color: Colors.blue, width: 10),
                          BarChartRodData(toY: 9000, color: Color(0xFF2E8B57), width: 10),
                        ]),
                        // Mountain Cabin
                        BarChartGroupData(x: 3, barRods: [
                          BarChartRodData(toY: 48, color: Colors.blue, width: 10),
                          BarChartRodData(toY: 9800, color: Color(0xFF2E8B57), width: 10),
                        ]),
                        // Bungalow
                        BarChartGroupData(x: 4, barRods: [
                          BarChartRodData(toY: 28, color: Colors.blue, width: 10),
                          BarChartRodData(toY: 11000, color: Color(0xFF2E8B57), width: 10),
                        ]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.square, size: 10, color: Colors.blue),
                    SizedBox(width: 6),
                    Text('Bookings', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 16),
                    Icon(Icons.square, size: 10, color: Color(0xFF2E8B57)),
                    SizedBox(width: 6),
                    Text('Revenue (\$)', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Top Performing Property',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text('Beach Villa', style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Bookings: 36', style: TextStyle(color: Colors.white)),
                      Text('Revenue: \$16,200', style: TextStyle(color: Colors.white)),
                      Text('Avg Rating: 4.9 ⭐', style: TextStyle(color: Colors.white)),
                      Text('Occupancy: 92%', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _RevenueTab._quickStat('Avg Booking Value', '\$338', Colors.green),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Avg Stay Duration', '3.2 nights', Colors.blue),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Return Customer Rate', '28%', Colors.purple),
                    const SizedBox(height: 8),
                    _RevenueTab._quickStat('Cancellation Rate', '5.2%', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}