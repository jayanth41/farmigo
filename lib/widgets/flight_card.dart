import 'package:flutter/material.dart';
import 'package:skybase/services/duffel_service.dart' as duffel;

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
  final duffel.Offer offer;

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
                Builder(
          builder: (_) {
          final segment = (offer.slices.isNotEmpty && offer.slices.first.segments.isNotEmpty)
            ? offer.slices.first.segments.first
            : null;

          final airlineName = offer.airlineName;
          final airlineLogo = offer.airlineLogo;
          final flightNumber = offer.flightNumber;

                    return Row(
                      children: [
                        if (airlineLogo.isNotEmpty)
                          Image.network(
                            airlineLogo,
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
                        Expanded(
                          child: Text(
                            flightNumber.isNotEmpty
                                ? "$airlineName $flightNumber"
                                : airlineName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
                Text(
              // prefer displayPrice from duffel model which formats INR conversion
              "${offer.currencySymbol} ${offer.totalAmount.toStringAsFixed(2)}",
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
                Builder(
                    builder: (_) {
                    final segment = (offer.slices.isNotEmpty && offer.slices.first.segments.isNotEmpty)
                        ? offer.slices.first.segments.first
                        : null;
                    final origin = segment?.departureAirportIata ?? "---";
                    final destination = segment?.arrivalAirportIata ?? "---";
                    return Text("$origin → $destination");
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Builder(
                    builder: (_) {
                    final duration = offer.duration;
                    return Text(duration);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
