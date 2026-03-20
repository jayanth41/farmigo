import 'package:flutter/material.dart';
import '../models/offer.dart';
import '../widgets/flight_card.dart';

class FlightResultsScreen extends StatefulWidget {
  final List<Offer> offers;

  const FlightResultsScreen({super.key, required this.offers});

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {

  String _sortType = "price";
  bool _nonStopOnly = false;

  List<Offer> get sortedOffers {
    List<Offer> list = List.from(widget.offers);

    if (_nonStopOnly) {
      list = list.where((o) => o.stops == 0).toList();
    }

    if (_sortType == "price") {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortType == "duration") {
      list.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    } else if (_sortType == "departure") {
      list.sort((a, b) => a.departureTimestamp.compareTo(b.departureTimestamp));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {

    if (widget.offers.isEmpty) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                ChoiceChip(
                  label: const Text("Cheapest"),
                  selected: _sortType == "price",
                  onSelected: (_) {
                    setState(() => _sortType = "price");
                  },
                ),

                ChoiceChip(
                  label: const Text("Fastest"),
                  selected: _sortType == "duration",
                  onSelected: (_) {
                    setState(() => _sortType = "duration");
                  },
                ),

                ChoiceChip(
                  label: const Text("Departure"),
                  selected: _sortType == "departure",
                  onSelected: (_) {
                    setState(() => _sortType = "departure");
                  },
                ),

                ChoiceChip(
                  label: const Text("Non‑stop"),
                  selected: _nonStopOnly,
                  onSelected: (_) {
                    setState(() => _nonStopOnly = !_nonStopOnly);
                  },
                ),

              ],
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