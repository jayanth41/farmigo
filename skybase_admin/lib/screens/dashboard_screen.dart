import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // KPI Cards Row
          Row(
            children: [
              _buildCard("Total Users", "1,240"),
              const SizedBox(width: 16),
              _buildCard("Total Owners", "85"),
              const SizedBox(width: 16),
              _buildCard("Active Bookings", "32"),
              const SizedBox(width: 16),
              _buildCard("Revenue", "₹2,45,000"),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            "Recent Activity",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text("New owner registered"),
                ),
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text("Booking confirmed"),
                ),
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text("Payment received"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}