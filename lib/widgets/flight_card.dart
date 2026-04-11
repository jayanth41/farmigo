import 'package:flutter/material.dart';
import '../models/offer.dart';

String _formatDuration(String? iso) {
  if (iso == null || iso.isEmpty) return "--";
  final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?');
  final m = regex.firstMatch(iso);
  if (m == null) return iso;
  final h = m.group(1) ?? '0';
  final min = m.group(2) ?? '0';
  return "${h}h ${min}m";
}

String _currencySymbol(String? code) {
  switch (code) {
    case 'INR':
      return '₹';
    case 'GBP':
      return '£';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    default:
      return code ?? '';
  }
}

class FlightCard extends StatelessWidget {
  final Offer offer;

  const FlightCard({
    super.key,
    required this.offer,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      // Leave onTap null so parent GestureDetector can handle taps (navigation)
      onTap: null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Airline + Price badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (offer.airlineLogo.isNotEmpty)
                      Image.network(
                        offer.airlineLogo,
                        width: 30,
                        height: 30,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.flight, size: 24),
                      )
                    else
                      const Icon(Icons.flight, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      offer.airlineName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    offer.displayPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Time + flight path
            Row(
              children: [

                /// Departure
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.departureTime ?? "--",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      offer.origin,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(width: 10),

                /// Path
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _formatDuration(offer.duration),
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Expanded(child: Divider(thickness: 1)),
                          Icon(Icons.flight, size: 16, color: Colors.grey),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                /// Arrival
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      offer.arrivalTime ?? "--",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      offer.destination,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// Bottom tags
            Row(
              children: [
                if (offer.isNonStop == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Non-stop",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),

                const SizedBox(width: 8),

                if (offer.flightNumber.isNotEmpty)
                  Text(
                    offer.flightNumber,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
