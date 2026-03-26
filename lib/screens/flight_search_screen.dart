// Updated Flight Search Screen with advanced autocomplete UI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/duffel_service.dart';
import '../services/airport_service.dart';
import 'order_creation_screen.dart';
import '../widgets/flight_card.dart';
import '../models/offer.dart';

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
  List<Offer> _allOffers = [];
  String? _errorMessage;

  String _sortType = "cheapest";
  bool _nonStopOnly = false;
  final Set<String> _selectedAirlines = {};
  String? _departurePeriodFilter;

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
      // STEP 1: Create offer request
      final response = await _duffelService.searchOffers(
        origin: _departureController.text,
        destination: _arrivalController.text,
        departureDate: _departureDateController.text,
        adults: int.tryParse(_passengersController.text) ?? 1,
      );

      final requestId = response['data']?['id'];

      if (requestId == null) {
        throw Exception('Failed to get request ID');
      }

      // STEP 2: Fetch offers using request ID
      final offers = await _duffelService.getOffers(requestId);

      setState(() {
        _allOffers = offers;
        _offers = List.from(_allOffers);
        _sortOffers();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _sortOffers() {
    _offers = List.from(_allOffers);

    if (_nonStopOnly) {
      _offers = _offers.where((o) => o.isNonStop).toList();
    }

    if (_selectedAirlines.isNotEmpty) {
      _offers = _offers.where((o) => _selectedAirlines.contains(o.airlineName)).toList();
    }

    // departure period filter removed (field not available on Offer)

    if (_sortType == "cheapest") {
      _offers.sort((a, b) => a.priceInINR.compareTo(b.priceInINR));
    } else if (_sortType == "fastest") {
      _offers.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    } else if (_sortType == "best") {
      // approximate best = cheapest + fastest (weighted)
      _offers.sort((a, b) {
        final aScore = a.priceInINR + a.durationMinutes;
        final bScore = b.priceInINR + b.durationMinutes;
        return aScore.compareTo(bScore);
      });
    }
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 16, width: 120, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 20, width: 40, color: Colors.grey.shade300),
              Container(height: 14, width: 80, color: Colors.grey.shade300),
              Container(height: 20, width: 40, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 36, color: Colors.grey.shade300),
        ],
      ),
    );
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
        // Extract only IATA code (e.g., "Hyderabad (HYD)" -> HYD)
        final code = selection.contains('(')
            ? selection.split('(').last.replaceAll(')', '').trim()
            : selection;
        controller.text = code;
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (value) {
            // Keep main controller in sync with typed value
            controller.text = value;
          },
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

            if (_isLoading)
              Column(
                children: List.generate(3, (_) => _buildSkeletonCard()),
              ),

            if (_offers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text("Cheapest"),
                      selected: _sortType == "cheapest",
                      onSelected: (_) {
                        setState(() {
                          _sortType = "cheapest";
                          _sortOffers();
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Fastest"),
                      selected: _sortType == "fastest",
                      onSelected: (_) {
                        setState(() {
                          _sortType = "fastest";
                          _sortOffers();
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Best Value"),
                      selected: _sortType == "best",
                      onSelected: (_) {
                        setState(() {
                          _sortType = "best";
                          _sortOffers();
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Non‑stop"),
                      selected: _nonStopOnly,
                      onSelected: (_) {
                        setState(() {
                          _nonStopOnly = !_nonStopOnly;
                          _sortOffers();
                        });
                      },
                    ),
                  ],
                ),
              ),
            if (_offers.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _allOffers
                    .map((o) => o.airlineName)
                    .toSet()
                    .map((airline) => FilterChip(
                          label: Text(airline),
                          selected: _selectedAirlines.contains(airline),
                          onSelected: (_) {
                            setState(() {
                              if (_selectedAirlines.contains(airline)) {
                                _selectedAirlines.remove(airline);
                              } else {
                                _selectedAirlines.add(airline);
                              }
                              _sortOffers();
                            });
                          },
                        ))
                    .toList(),
              ),
            if (_offers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Wrap(
                  spacing: 8,
                  children: ["Morning", "Afternoon", "Evening", "Night"]
                      .map((period) => ChoiceChip(
                            label: Text(period),
                            selected: _departurePeriodFilter == period,
                            onSelected: (_) {
                              setState(() {
                                if (_departurePeriodFilter == period) {
                                  _departurePeriodFilter = null;
                                } else {
                                  _departurePeriodFilter = period;
                                }
                                _sortOffers();
                              });
                            },
                          ))
                      .toList(),
                ),
              ),

            if (!_isLoading && _offers.isEmpty && _errorMessage == null)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.flight_takeoff, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "No flights found",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _offers.length,
              itemBuilder: (context, index) {
                final offer = _offers[index];
                return GestureDetector(
                  onTap: () {
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
                  child: FlightCard(
                    offer: offer,
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    _departureDateController.dispose();
    _passengersController.dispose();
    super.dispose();
  }
}