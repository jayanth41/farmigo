import 'package:flutter/material.dart';
import '../services/duffel_service.dart';

class FlightScreen extends StatefulWidget {
  const FlightScreen({super.key});

  @override
  State<FlightScreen> createState() => _FlightScreenState();
}

class _FlightScreenState extends State<FlightScreen> {
  final DuffelService _duffelService = DuffelService();
  List<Offer> _offers = [];
  bool _loading = false;

  Future<void> searchFlights() async {
    setState(() => _loading = true);

    try {
      final response = await _duffelService.searchOffers(
        origin: "HYD",
        destination: "DXB",
        departureDate: "2026-06-01",
      );

      final data = response['data'];

      if (data is Map && data['offers'] != null) {
        final offersJson = data['offers'] as List;

        setState(() {
          _offers = offersJson
              .map((o) => Offer.fromJson(o))
              .toList();
        });
      }
    } catch (e) {
      print("Flight error: $e");
    }

    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    searchFlights();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flights")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _offers.length,
              itemBuilder: (context, index) {
                final offer = _offers[index];

                return ListTile(
                  title: Text(offer.displayPrice),
                  subtitle: Text(offer.departureInfo),
                );
              },
            ),
    );
  }
}