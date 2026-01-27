import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OffersBanner extends StatelessWidget {
  const OffersBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Exclusive Offers",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: navigate to offers screen
                },
                child: const Row(
                  children: [
                    Text("View all"),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              )
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _OfferCard(
                  title: "Weekend Deals",
                  subtitle: "Up to 40% off",
                  icon: Icons.local_fire_department,
                  gradient: LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF10B981)],
                  ),
                ),
                _OfferCard(
                  title: "Early Bird",
                  subtitle: "Save 15%",
                  icon: Icons.percent,
                  gradient: LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  ),
                ),
                _OfferCard(
                  title: "First Booking",
                  subtitle: "20% off",
                  icon: Icons.star_border,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                  ),
                ),
                SizedBox(width: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;

  const _OfferCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON CIRCLE
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
