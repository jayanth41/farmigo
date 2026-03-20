import 'package:flutter/material.dart';

class FlightCard extends StatelessWidget {
  final dynamic offer;

  const FlightCard({
    super.key,
    required this.offer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        /// Airline + Price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (offer.airlineLogo.isNotEmpty)
                  Image.network(
                    offer.airlineLogo,
                    width: 22,
                    height: 22,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.flight_takeoff,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                  )
                else
                  const Icon(Icons.flight_takeoff, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  offer.flightNumber.isNotEmpty
                      ? "${offer.airlineDisplay} ${offer.flightNumber}"
                      : offer.airlineDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              offer.displayPrice,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// Route + Duration
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text("${offer.origin} → ${offer.destination}"),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(offer.duration),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
