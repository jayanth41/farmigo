import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skybase/services/duffel_service.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  late DuffelService _duffelService;
  
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  final TextEditingController _departureDateController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();
  final TextEditingController _passengersController = TextEditingController(text: '1');

  bool _isLoading = false;
  List<Offer> _offers = [];
  String? _sessionId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _duffelService = DuffelService();
  }

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    _departureDateController.dispose();
    _returnDateController.dispose();
    _passengersController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _searchFlights() async {
    if (_departureController.text.isEmpty ||
        _arrivalController.text.isEmpty ||
        _departureDateController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _offers = [];
    });

    try {
      // Step 1: Create search session
      final searchResponse = await _duffelService.searchFlights(
        departureAirportIata: _departureController.text.toUpperCase(),
        arrivalAirportIata: _arrivalController.text.toUpperCase(),
        departureDate: _departureDateController.text,
        returnDate: _returnDateController.text,
        passengers: int.parse(_passengersController.text),
      );

      _sessionId = searchResponse.id;

      // Step 2: Get offers (with polling for results)
      await _pollForOffers(_sessionId!);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pollForOffers(String sessionId) async {
    // Poll for up to 30 seconds for results
    int attempts = 0;
    const maxAttempts = 30;

    while (attempts < maxAttempts) {
      try {
        final offers = await _duffelService.getSearchResults(sessionId);
        
        if (offers.isNotEmpty) {
          setState(() {
            _offers = offers;
          });
          return;
        }

        // Wait before next poll
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      } catch (e) {
        // Continue polling even if there's an error
        attempts++;
      }
    }

    setState(() {
      _errorMessage = 'No results found. Please try again.';
    });
  }

  void _selectOffer(Offer offer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderCreationScreen(
          offer: offer,
          duffelService: _duffelService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Search'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Form
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Search Flights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Departure Airport
                    TextField(
                      controller: _departureController,
                      decoration: InputDecoration(
                        labelText: 'Departure Airport (IATA)',
                        hintText: 'e.g., LAX',
                        prefixIcon: const Icon(Icons.flight_takeoff),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),

                    // Arrival Airport
                    TextField(
                      controller: _arrivalController,
                      decoration: InputDecoration(
                        labelText: 'Arrival Airport (IATA)',
                        hintText: 'e.g., JFK',
                        prefixIcon: const Icon(Icons.flight_land),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),

                    // Departure Date
                    TextField(
                      controller: _departureDateController,
                      decoration: InputDecoration(
                        labelText: 'Departure Date',
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_departureDateController),
                    ),
                    const SizedBox(height: 12),

                    // Return Date (Optional)
                    TextField(
                      controller: _returnDateController,
                      decoration: InputDecoration(
                        labelText: 'Return Date (Optional)',
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_returnDateController),
                    ),
                    const SizedBox(height: 12),

                    // Passengers
                    TextField(
                      controller: _passengersController,
                      decoration: InputDecoration(
                        labelText: 'Number of Passengers',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Search Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _searchFlights,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Search Flights'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            const SizedBox(height: 20),

            // Results
            if (_offers.isNotEmpty) ...[
              Text(
                'Found ${_offers.length} flight(s)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _offers.length,
                itemBuilder: (context, index) {
                  final offer = _offers[index];
                  return OfferCard(
                    offer: offer,
                    onSelect: () => _selectOffer(offer),
                  );
                },
              ),
            ] else if (!_isLoading && _sessionId != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Text(
                  'No flights found for your search criteria.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onSelect;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  offer.displayPrice,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Offer ID: ${offer.id.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route info
            if (offer.slices.isNotEmpty) ...[
              Text(
                'Outbound: ${offer.slices[0].toString()}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (offer.slices.length > 1)
                Text(
                  'Return: ${offer.slices[1].toString()}',
                  style: const TextStyle(fontSize: 14),
                ),
            ],
            const SizedBox(height: 16),

            // Select button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Select & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
