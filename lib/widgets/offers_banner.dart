import 'package:flutter/material.dart';

class OffersBanner extends StatelessWidget {
  const OffersBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.local_offer, color: Colors.white, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Limited-time: 20% off on weekend bookings — use code WEEKEND20',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 8),
            Text('Shop', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
