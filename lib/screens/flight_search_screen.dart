// Updated Flight Search Screen with advanced autocomplete UI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/duffel_service.dart';
import '../services/airport_service.dart';
import 'order_creation_screen.dart';

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
  final TextEditingController _passengersController = TextEditingController(text: '1');

  bool _isLoading = false;
  List<Offer> _offers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _duffelService = DuffelService();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      _departureDateController.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _searchFlights() async {
    if (_departureController.text.isEmpty ||
        _arrivalController.text.isEmpty ||
        _departureDateController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _offers.clear();
      _errorMessage = null;
    });

    try {
      final response = await _duffelService.searchOffers(
        origin: AirportService.getIata(_departureController.text),
        destination: AirportService.getIata(_arrivalController.text),
        departureDate: _departureDateController.text,
        adults: int.parse(_passengersController.text),
      );

      final data = response['data'];
      List<dynamic>? offersJson;

      if (data is Map && data['offers'] != null) {
        offersJson = data['offers'];
      } else if (data is List) {
        offersJson = data;
      }

      if (offersJson != null) {
        setState(() {
          _offers = offersJson!
              .map((o) => Offer.fromJson(o as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _airportField(TextEditingController controller, String label, IconData icon) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return AirportService.search(textEditingValue.text)
            .map((a) => "${a.city} (${a.iata})");
      },
      onSelected: (selection) {
        controller.text = selection.split('(').first.trim();
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        controller.text = textController.text;
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Flights')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _airportField(
                        _departureController, 'From City / Airport', Icons.flight_takeoff),
                    const SizedBox(height: 6),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.swap_vert, size: 28),
                        onPressed: () {
                          final temp = _departureController.text;
                          _departureController.text = _arrivalController.text;
                          _arrivalController.text = temp;
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    _airportField(
                        _arrivalController, 'To City / Airport', Icons.flight_land),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _departureDateController,
                      readOnly: true,
                      onTap: _selectDate,
                      decoration: InputDecoration(
                        labelText: 'Departure Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passengersController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Passengers',
                        prefixIcon: const Icon(Icons.people),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _searchFlights,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Search Flights'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _offers.length,
              itemBuilder: (context, index) {
                final offer = _offers[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flight, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  "Flight Offer",
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
                        const SizedBox(height: 8),
                        Text(
                          "Offer ID: ${offer.id}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderCreationScreen(
                                    offer: offer,
                                    duffelService: _duffelService,
                                  ),
                                ),
                              );
                            },
                            child: const Text("Select Flight"),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}