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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          /// Airline + Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Flexible(
                      child: Text(
                        offer.flightNumber.isNotEmpty
                            ? "${offer.airlineName} ${offer.flightNumber}"
                            : offer.airlineName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
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
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.route, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Builder(
                        builder: (_) {
                          return Text(
                            "${offer.origin} → ${offer.destination}",
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_formatDuration(offer.duration)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
