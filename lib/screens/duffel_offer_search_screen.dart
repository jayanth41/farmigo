import 'package:flutter/material.dart';
import 'package:skybase/services/duffel_service.dart';

/// Simple example screen that calls DuffelService.searchOffers and displays results
class DuffelOfferSearchScreen extends StatefulWidget {
  const DuffelOfferSearchScreen({super.key});

  @override
  State<DuffelOfferSearchScreen> createState() => _DuffelOfferSearchScreenState();
}

class _DuffelOfferSearchScreenState extends State<DuffelOfferSearchScreen> {
  final _originController = TextEditingController(text: 'LHR');
  final _destinationController = TextEditingController(text: 'JFK');
  final _dateController = TextEditingController(text: '2026-03-01');
  final _passengersController = TextEditingController(text: '1');

  final DuffelService _service = DuffelService();
  bool _loading = false;
  String? _error;
  List<dynamic> _offers = [];

  Future<void> _search() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty || _dateController.text.isEmpty) {
      setState(() => _error = 'Please provide origin, destination and date');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _offers = [];
    });

    try {
      final resp = await _service.searchOffers(
        origin: _originController.text.toUpperCase(),
        destination: _destinationController.text.toUpperCase(),
        departureDate: _dateController.text,
        adults: int.tryParse(_passengersController.text) ?? 1,
      );

      // Print full response for debugging
      debugPrint('Duffel searchOffers response: $resp');

      // Duffel returns data in resp['data'] typically
      final data = resp['data'];
      if (data is List) {
        setState(() => _offers = data);
      } else if (data != null) {
        // Some responses may wrap offers in attributes
        setState(() => _offers = [data]);
      } else {
        setState(() => _offers = []);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duffel Offer Requests')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _originController,
              decoration: const InputDecoration(labelText: 'Origin (IATA)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination (IATA)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Departure Date (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passengersController,
              decoration: const InputDecoration(labelText: 'Passengers'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _search,
              child: _loading ? const CircularProgressIndicator() : const Text('Search Offers'),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            Expanded(
              child: _offers.isEmpty
                  ? const Center(child: Text('No offers'))
                  : ListView.builder(
                      itemCount: _offers.length,
                      itemBuilder: (context, index) {
                        final offer = _offers[index] as Map<String, dynamic>;
                        final id = offer['id'] ?? offer['offer_id'] ?? 'id';
                        final totalAmount = offer['total_amount'] ?? offer['attributes']?['total_amount'];
                        final totalCurrency = offer['total_currency'] ?? offer['attributes']?['total_currency'];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('Offer: ${id.toString().substring(0, 8)}'),
                            subtitle: Text('${totalCurrency ?? ''} ${totalAmount ?? ''}'),
                            onTap: () => debugPrint('Tapped offer: $offer'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
