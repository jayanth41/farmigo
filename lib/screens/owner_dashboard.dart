import 'package:flutter/material.dart';
import 'owner_properties_screen.dart';
import 'owner_booking_screen.dart';
import 'owner_earning_screen.dart';
import 'add_property_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Owner Dashboard"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            tile(
              icon: Icons.home_work,
              title: "My Properties",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerPropertiesScreen(),
                  ),
                );
              },
            ),
            tile(
              icon: Icons.add_business,
              title: "Add Property",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddPropertyScreen(),
                  ),
                );
              },
            ),
            tile(
              icon: Icons.book_online,
              title: "Bookings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerBookingsScreen(),
                  ),
                );
              },
            ),
            tile(
              icon: Icons.currency_rupee,
              title: "Earnings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EarningsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
