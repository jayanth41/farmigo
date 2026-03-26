import 'package:flutter/material.dart';
import '../services/duffel_service.dart' as duffel;
import '../widgets/flight_card.dart';

class FlightResultsScreen extends StatefulWidget {
  final List<duffel.Offer> offers;

  const FlightResultsScreen({super.key, required this.offers});

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {

  String _sortType = "price";
  bool _nonStopOnly = false;

  List<duffel.Offer> get sortedOffers {
    List<duffel.Offer> list = widget.offers
        .where((o) {
          try {
            return o.priceInINR >= 0;
          } catch (_) {
            return false;
          }
        })
        .toList();

    if (_nonStopOnly) {
      list = list.where((o) {
        final stops = (o.slices.isNotEmpty ? o.slices.first.segments.length - 1 : 0);
        return stops == 0;
      }).toList();
    }

    if (_sortType == "price") {
      list.sort((a, b) => a.priceInINR.compareTo(b.priceInINR));
    } else if (_sortType == "duration") {
      int durationMinutes(duffel.Offer of) {
        try {
          if (of.slices.isEmpty) return 0;
          final segs = of.slices.first.segments;
          if (segs.isEmpty) return 0;
          final dep = DateTime.tryParse(segs.first.departureAt);
          final arr = DateTime.tryParse(segs.last.arrivalAt);
          if (dep == null || arr == null) return 0;
          return arr.difference(dep).inMinutes;
        } catch (_) {
          return 0;
        }
      }
      list.sort((a, b) => durationMinutes(a).compareTo(durationMinutes(b)));
    } else if (_sortType == "departure") {
      int depTs(duffel.Offer of) {
        try {
          if (of.slices.isEmpty) return 0;
          final segs = of.slices.first.segments;
          if (segs.isEmpty) return 0;
          final dep = DateTime.tryParse(segs.first.departureAt);
          return dep?.millisecondsSinceEpoch ?? 0;
        } catch (_) {
          return 0;
        }
      }
      list.sort((a, b) => depTs(a).compareTo(depTs(b)));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {

    if (sortedOffers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Flights")),
        body: const Center(
          child: Text(
            "No flights found",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flight Results"),
      ),
      body: Column(
        children: [

          /// SORT BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 8),

                  ChoiceChip(
                    label: const Text("Cheapest"),
                    selected: _sortType == "price",
                    onSelected: (_) {
                      setState(() => _sortType = "price");
                    },
                  ),

                  const SizedBox(width: 8),

                  ChoiceChip(
                    label: const Text("Fastest"),
                    selected: _sortType == "duration",
                    onSelected: (_) {
                      setState(() => _sortType = "duration");
                    },
                  ),

                  const SizedBox(width: 8),

                  ChoiceChip(
                    label: const Text("Departure"),
                    selected: _sortType == "departure",
                    onSelected: (_) {
                      setState(() => _sortType = "departure");
                    },
                  ),

                  const SizedBox(width: 8),

                  ChoiceChip(
                    label: const Text("Non‑stop"),
                    selected: _nonStopOnly,
                    onSelected: (_) {
                      setState(() => _nonStopOnly = !_nonStopOnly);
                    },
                  ),

                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          const Divider(),

          /// RESULTS LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedOffers.length,
              itemBuilder: (context, index) {
                final offer = sortedOffers[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FlightCard(offer: offer),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}