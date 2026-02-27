import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color.fromARGB(255, 41, 70, 92),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Offers & Coupons', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: colorScheme.onPrimary, size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Offers & Coupons",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary)),
            Text("Save more on your bookings",
              style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9))),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            const OfferCard(
              title: "First Booking Special",
              subtitle: "Get 25% off on your first booking",
              code: "FIRST25",
              expiry: "Expires in 15 days",
              discount: "25% OFF",
              colors: [Color(0xFFB14FFF), Color(0xFFFF5FC1)],
            ),

            const OfferCard(
              title: "Weekend Getaway",
              subtitle: "Save ₹50 on weekend bookings",
              code: "WEEKEND50",
              expiry: "Expires in 7 days",
              discount: "₹50 OFF",
              colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
            ),

            const OfferCard(
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
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.12), blurRadius: 6),
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
                          style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
            Text(subtitle,
              style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.9))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(discount,
                      style: TextStyle(color: colorScheme.onPrimary)),
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
                      border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(10),
                      color: theme.colorScheme.surface,
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
                  style: TextStyle(color: colorScheme.secondary)),
            ),
          )
        ],
      ),
    );
  }
}
