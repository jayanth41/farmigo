import 'package:flutter/material.dart';
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF9),
      body: SafeArea(
        child: ListView(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.card_giftcard, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Offers & Coupons",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text("Save more on your bookings",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            OfferCard(
              title: "First Booking Special",
              subtitle: "Get 25% off on your first booking",
              code: "FIRST25",
              expiry: "Expires in 15 days",
              discount: "25% OFF",
              colors: [Color(0xFFB14FFF), Color(0xFFFF5FC1)],
            ),

            OfferCard(
              title: "Weekend Getaway",
              subtitle: "Save ₹50 on weekend bookings",
              code: "WEEKEND50",
              expiry: "Expires in 7 days",
              discount: "₹50 OFF",
              colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
            ),

            OfferCard(
              title: "Long Stay Discount",
              subtitle: "Book 7+ days and save 30%",
              code: "LONGSTAY30",
              expiry: "Expires in 30 days",
              discount: "30% OFF",
              colors: [Color(0xFF00C853), Color(0xFF64DD17)],
            ),

            const SizedBox(height: 10),

            // HOW TO USE
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("How to use coupons?",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("• Copy your preferred coupon code"),
                  Text("• Select a property and proceed to checkout"),
                  Text("• Apply the code at payment page"),
                  Text("• Enjoy your discount!"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class OfferCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String code;
  final String expiry;
  final String discount;
  final List<Color> colors;

  const OfferCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.expiry,
    required this.discount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          // Top gradient strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text(subtitle,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(discount,
                      style: const TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),

          // Coupon row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: Text(code,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Clipboard copy later
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy"),
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text("⏰ $expiry",
                  style: const TextStyle(color: Colors.orange)),
            ),
          )
        ],
      ),
    );
  }
}
