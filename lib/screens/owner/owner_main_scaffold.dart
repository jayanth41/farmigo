import 'package:flutter/material.dart';

import '../owner_dashboard.dart';
import '../owner_booking_screen.dart';
import '../owner_reviews_screen.dart';
import '../profile_screen.dart';

class OwnerMainScaffold extends StatefulWidget {
  final int initialIndex;

  const OwnerMainScaffold({super.key, this.initialIndex = 0});

  @override
  State<OwnerMainScaffold> createState() => _OwnerMainScaffoldState();
}

class _OwnerMainScaffoldState extends State<OwnerMainScaffold> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  final List<Widget> pages = const [
    OwnerDashboard(),
    OwnerBookingsScreen(),
    OwnerReviewsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF29465C),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (i) {
              final icons = [
                Icons.dashboard,
                Icons.calendar_month,
                Icons.star,
                Icons.person
              ];

              final labels = [
                "Dashboard",
                "Bookings",
                "Reviews",
                "Profile"
              ];

              final bool selected = index == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      index = i;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[i],
                          color: selected
                              ? const Color(0xFF29465C)
                              : Colors.white,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? const Color(0xFF29465C)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}