import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Analytics Dashboard",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Monthly Revenue
          _buildCard("Monthly Revenue", "₹1,20,000"),

          const SizedBox(height: 12),

          // Booking Growth
          _buildCard("Booking Growth", "+18%"),

          const SizedBox(height: 12),

          // Top Properties
          const Text(
            "Top Performing Properties",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              children: const [
                ListTile(title: Text("Farmhouse A"), trailing: Text("₹50,000")),
                ListTile(title: Text("Villa B"), trailing: Text("₹42,000")),
                ListTile(title: Text("Resort C"), trailing: Text("₹35,000")),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}