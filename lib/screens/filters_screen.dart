import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/category.dart';
import '../filters/filters_provider.dart';

class FiltersScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersApplied;
  final Map<String, dynamic> initialFilters;
  final Category? category;

  const FiltersScreen({
    super.key,
    required this.onFiltersApplied,
    required this.initialFilters,
    this.category,
  });

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  // Common
  late RangeValues _priceRange;
  late double _maxDistance;
  late bool _luxuryOnly;
  late double _minRating;
  late Map<String, bool> _amenities;
  late Map<String, bool> _propertyTypes;
  late String _sortOption;

  // Shared UI pieces
  late List<String> _locationOptions;
  late String _locationText;
  late TextEditingController _locationController;

  // Farmhouse / Villa
  late int _guestsCount;
  late int _bedroomsCount;
  late int _bathroomsCount;
  late Map<String, bool> _houseAmenities; // Pool, AC, Wifi ...
  late Map<String, bool> _specialOptions; // party, family, pet, bachelor, event
  DateTimeRange? _availabilityRange;

  // Hotel
  late double _starRating;
  late String _roomType;
  late bool _freeBreakfast;
  late int _hotelGuestsCount;
  DateTimeRange? _hotelDateRange;

  // Flights
  late String _departureCity;
  late String _arrivalCity;
  DateTime? _departureDate;
  DateTime? _returnDate;
  late List<String> _airlines;
  late String _selectedAirline;
  late String _stopsOption;
  late String _departureTimeOfDay;
  late String _flightClass;
  late RangeValues _flightPriceRange;

  // Car
  late String _carType;
  late String _fuelType;
  late RangeValues _pricePerDay;
  late String _transmission;
  DateTime? _pickupDateTime;
  DateTime? _dropoffDateTime;
  late int _seatingCapacity;

  // Hourly
  late RangeValues _pricePerHour;
  late String _timeSlot;
  late bool _acOnly;
  late int _capacity;
  late int _hourlyDurationHours;

  @override
  void initState() {
    super.initState();
    // Initialize from initial filters with sensible defaults
    _priceRange = widget.initialFilters['priceRange'] ?? const RangeValues(0, 10000);
    _maxDistance = widget.initialFilters['maxDistance'] ?? 100;
    _luxuryOnly = widget.initialFilters['luxuryOnly'] ?? false;
    _minRating = widget.initialFilters['minRating'] ?? 0;
    _amenities = Map.from(widget.initialFilters['amenities'] ?? {
      'Pool': false,
      'WiFi': false,
      'Kitchen': false,
      'Breakfast': false,
    });
    _propertyTypes = Map.from(widget.initialFilters['propertyTypes'] ?? {
      'Farmhouse': false,
      'Villa': false,
      'Hotel': false,
      'Apartment': false,
      'Cottage': false,
      'Homestay': false,
    });
    _sortOption = widget.initialFilters['sortOption'] ?? 'Relevance';

    _locationOptions = List<String>.from(widget.initialFilters['locationOptions'] ?? ['Hyderabad', 'Bengaluru', 'Mumbai', 'Chennai']);
    _locationText = widget.initialFilters['location'] ?? _locationOptions.first;
    _locationController = TextEditingController(text: _locationText);

    // Farmhouse/Villa
    _guestsCount = widget.initialFilters['guestsCount'] ?? 2;
    _bedroomsCount = widget.initialFilters['bedrooms'] ?? 1;
    _bathroomsCount = widget.initialFilters['bathrooms'] ?? 1;
    _houseAmenities = Map.from(widget.initialFilters['houseAmenities'] ?? {
      'Pool': false,
      'AC': false,
      'Wifi': false,
      'Parking': false,
      'Kitchen': false,
      'BBQ': false,
      'Garden': false,
      'Power Backup': false,
    });
    _specialOptions = Map.from(widget.initialFilters['specialOptions'] ?? {
      'Party allowed': false,
      'Family friendly': true,
      'Pet friendly': false,
      'Bachelor allowed': false,
      'Event allowed': false,
    });
    _availabilityRange = widget.initialFilters['availabilityRange'];

    // Hotel
    _starRating = widget.initialFilters['starRating'] ?? 0.0;
    _roomType = widget.initialFilters['roomType'] ?? 'Single';
    _freeBreakfast = widget.initialFilters['freeBreakfast'] ?? false;
    _hotelGuestsCount = widget.initialFilters['hotelGuestsCount'] ?? 1;
    _hotelDateRange = widget.initialFilters['hotelDateRange'];

    // Flights
    _departureCity = widget.initialFilters['departureCity'] ?? _locationOptions.first;
    _arrivalCity = widget.initialFilters['arrivalCity'] ?? (_locationOptions.length > 1 ? _locationOptions[1] : _locationOptions.first);
    _departureDate = widget.initialFilters['departureDate'];
    _returnDate = widget.initialFilters['returnDate'];
    _airlines = List<String>.from(widget.initialFilters['airlines'] ?? ['Any', 'Airline A', 'Airline B']);
    _selectedAirline = widget.initialFilters['selectedAirline'] ?? 'Any';
    _stopsOption = widget.initialFilters['stopsOption'] ?? 'Any';
    _departureTimeOfDay = widget.initialFilters['departureTimeOfDay'] ?? 'Any';
    _flightClass = widget.initialFilters['flightClass'] ?? 'Economy';
    _flightPriceRange = widget.initialFilters['flightPriceRange'] ?? const RangeValues(0, 100000);

    // Car
    _carType = widget.initialFilters['carType'] ?? 'Hatchback';
    _fuelType = widget.initialFilters['fuelType'] ?? 'Petrol';
    _pricePerDay = widget.initialFilters['pricePerDay'] ?? const RangeValues(0, 10000);
    _transmission = widget.initialFilters['transmission'] ?? 'Automatic';
    _pickupDateTime = widget.initialFilters['pickupDateTime'];
    _dropoffDateTime = widget.initialFilters['dropoffDateTime'];
    _seatingCapacity = widget.initialFilters['seatingCapacity'] ?? 4;

    // Hourly
    _pricePerHour = widget.initialFilters['pricePerHour'] ?? const RangeValues(0, 1000);
    _timeSlot = widget.initialFilters['timeSlot'] ?? 'Morning';
    _acOnly = widget.initialFilters['acOnly'] ?? false;
    _capacity = widget.initialFilters['capacity'] ?? 2;
    _hourlyDurationHours = widget.initialFilters['hourlyDurationHours'] ?? 2;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<DateTimeRange?> _pickDateRange(BuildContext context, {DateTimeRange? initial}) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initial,
    );
    return picked;
  }

  Future<DateTime?> _pickDateTime(BuildContext context, {DateTime? initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()));
    if (time == null) return DateTime(date.year, date.month, date.day);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _applyFilters() {
    final result = <String, dynamic>{
      'priceRange': _priceRange,
      'maxDistance': _maxDistance,
      'luxuryOnly': _luxuryOnly,
      'minRating': _minRating,
      'amenities': _amenities,
      'propertyTypes': _propertyTypes,
      'sortOption': _sortOption,
    };

    final cat = widget.category ?? Category.all;
    if (cat == Category.farmhouse || cat == Category.villa) {
      result.addAll({
        'location': _locationText,
        'priceRange': _priceRange,
        'guestsCount': _guestsCount,
        'bedrooms': _bedroomsCount,
        'bathrooms': _bathroomsCount,
        'houseAmenities': _houseAmenities,
        'specialOptions': _specialOptions,
        'minRating': _minRating >= 4.0 ? _minRating : _minRating,
        'availabilityRange': _availabilityRange,
        'sortOption': _sortOption,
      });
    } else if (cat == Category.hotel) {
      result.addAll({
        'location': _locationText,
        'priceRange': _priceRange,
        'starRating': _starRating,
        'roomType': _roomType,
        'amenities': _houseAmenities,
        'hotelGuestsCount': _hotelGuestsCount,
        'hotelDateRange': _hotelDateRange,
        'sortOption': _sortOption,
      });
    } else if (cat == Category.car) {
      result.addAll({
        'pickupLocation': _locationText,
        'pickupDateTime': _pickupDateTime,
        'dropoffDateTime': _dropoffDateTime,
        'pricePerDay': _pricePerDay,
        'carType': _carType,
        'fuelType': _fuelType,
        'transmission': _transmission,
        'seatingCapacity': _seatingCapacity,
        'sortOption': _sortOption,
      });
    } else if (cat == Category.hourly) {
      result.addAll({
        'location': _locationText,
        'pricePerHour': _pricePerHour,
        'durationHours': _hourlyDurationHours,
        'guestCapacity': _capacity,
        'roomType': _roomType,
        'amenities': _houseAmenities,
        'timeSlot': _timeSlot,
        'sortOption': _sortOption,
      });
    } else if (cat == Category.all) {
      // default/common
      result.addAll({
        'priceRange': _priceRange,
        'maxDistance': _maxDistance,
        'sortOption': _sortOption,
      });
    }

    // Flights: independent category
    else if (cat == Category.flights) {
      result.addAll({
        'departureCity': _departureCity,
        'arrivalCity': _arrivalCity,
        'departureDate': _departureDate,
        'returnDate': _returnDate,
        'flightPriceRange': _flightPriceRange,
        'selectedAirline': _selectedAirline,
        'stopsOption': _stopsOption,
        'departureTimeOfDay': _departureTimeOfDay,
        'flightClass': _flightClass,
        'sortOption': _sortOption,
      });
    }

    widget.onFiltersApplied(result);
    try {
      final provider = Provider.of<FiltersProvider>(context, listen: false);
      provider.setFilter(widget.category ?? Category.all, result);
    } catch (_) {}
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 10000);
      _maxDistance = 100;
      _luxuryOnly = false;
      _minRating = 0;
      _amenities.updateAll((key, value) => false);
      _propertyTypes.updateAll((key, value) => false);
      _sortOption = 'Relevance';

      _locationText = _locationOptions.first;
      _locationController.text = _locationText;

      // farmhouse
      _guestsCount = 2;
      _bedroomsCount = 1;
      _bathroomsCount = 1;
      _houseAmenities.updateAll((k, v) => false);
      _specialOptions.updateAll((k, v) => false);
      _availabilityRange = null;

      // hotel
      _starRating = 0.0;
      _roomType = 'Single';
      _freeBreakfast = false;
      _hotelGuestsCount = 1;
      _hotelDateRange = null;

      // flights
      _departureCity = _locationOptions.first;
      _arrivalCity = _locationOptions.length > 1 ? _locationOptions[1] : _locationOptions.first;
      _departureDate = null;
      _returnDate = null;
      _selectedAirline = 'Any';
      _stopsOption = 'Any';
      _departureTimeOfDay = 'Any';
      _flightClass = 'Economy';
      _flightPriceRange = const RangeValues(0, 100000);

      // car
      _carType = 'Hatchback';
      _fuelType = 'Petrol';
      _pricePerDay = const RangeValues(0, 10000);
      _transmission = 'Automatic';
      _pickupDateTime = null;
      _dropoffDateTime = null;
      _seatingCapacity = 4;

      // hourly
      _pricePerHour = const RangeValues(0, 1000);
      _timeSlot = 'Morning';
      _acOnly = false;
      _capacity = 2;
      _hourlyDurationHours = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category ?? Category.all;
  final amenitiesKeys = _amenities.keys.toList();
  String safeVal(String current, List<String> items) => items.contains(current) ? current : items.first;

    Widget buildCategoryBody() {
      switch (cat) {
        case Category.farmhouse:
        case Category.villa:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: _locationOptions.contains(_locationText) ? _locationText : _locationOptions.first,
                  isExpanded: true,
                  underline: Container(),
                  items: _locationOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _locationText = v ?? _locationOptions.first),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RangeSlider(values: _priceRange, min: 0, max: 10000, divisions: 100, labels: RangeLabels('₹${_priceRange.start.toInt()}', '₹${_priceRange.end.toInt()}'), onChanged: (r) => setState(() => _priceRange = r)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Guests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _guestsCount = (_guestsCount - 1).clamp(1, 50))), Text('$_guestsCount'), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _guestsCount = (_guestsCount + 1).clamp(1, 50)))])])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Bedrooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _bedroomsCount = (_bedroomsCount - 1).clamp(1, 20))), Text('$_bedroomsCount'), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _bedroomsCount = (_bedroomsCount + 1).clamp(1, 20)))])])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Bathrooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _bathroomsCount = (_bathroomsCount - 1).clamp(1, 20))), Text('$_bathroomsCount'), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _bathroomsCount = (_bathroomsCount + 1).clamp(1, 20)))])])),
              ]),
              const SizedBox(height: 12),
              const Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _houseAmenities.keys.map((k) => FilterChip(label: Text(k), selected: _houseAmenities[k] ?? false, onSelected: (v) => setState(() => _houseAmenities[k] = v))).toList()),
              const SizedBox(height: 12),
              const Text('Special options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _specialOptions.keys.map((k) => FilterChip(label: Text(k), selected: _specialOptions[k] ?? false, onSelected: (v) => setState(() => _specialOptions[k] = v))).toList()),
              const SizedBox(height: 12),
              Row(children: [const Expanded(child: Text('Rating (4★ & above)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))), Switch(value: _minRating >= 4.0, onChanged: (v) => setState(() => _minRating = v ? 4.0 : 0.0))]),
              const SizedBox(height: 12),
              const Text('Availability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () async { final picked = await _pickDateRange(context, initial: _availabilityRange); if (picked != null) setState(() => _availabilityRange = picked); }, child: Text(_availabilityRange == null ? 'Select date range' : '${_availabilityRange!.start.toLocal().toString().split(' ')[0]} → ${_availabilityRange!.end.toLocal().toString().split(' ')[0]}')),
              const SizedBox(height: 12),
              const Text('Sort by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
  child: DropdownButton<String>(
  value: safeVal(_sortOption, ['Relevance', 'Price', 'Rating', 'Distance']),
    isExpanded: true,
    underline: Container(),
    items: const [
      DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
      DropdownMenuItem(value: 'Price', child: Text('Price')),
      DropdownMenuItem(value: 'Rating', child: Text('Rating')),
      DropdownMenuItem(value: 'Distance', child: Text('Distance')),
    ],
    onChanged: (v) => setState(() => _sortOption = v ?? 'Relevance'),
  ),
)

            ],
          );

        case Category.hotel:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)), child: DropdownButton<String>(value: _locationOptions.contains(_locationText) ? _locationText : _locationOptions.first, isExpanded: true, underline: Container(), items: _locationOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _locationText = v ?? _locationOptions.first))),
              const SizedBox(height: 12),
              const Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RangeSlider(values: _priceRange, min: 0, max: 10000, divisions: 100, labels: RangeLabels('₹${_priceRange.start.toInt()}', '₹${_priceRange.end.toInt()}'), onChanged: (r) => setState(() => _priceRange = r)),
              const SizedBox(height: 12),
              const Text('Star Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [3,4,5].map((s) => ChoiceChip(label: Text('${s}★'), selected: _starRating==s.toDouble(), onSelected: (_) => setState(() => _starRating = s.toDouble()))).toList()),
              const SizedBox(height: 12),
              const Text('Room Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: safeVal(_roomType, ['Single', 'Double', 'Suite']),
                items: const [
                  DropdownMenuItem(value: 'Single', child: Text('Single')),
                  DropdownMenuItem(value: 'Double', child: Text('Double')),
                  DropdownMenuItem(value: 'Suite', child: Text('Suite')),
                ],
                onChanged: (v) => setState(() => _roomType = v ?? 'Single'),
              ),
              const SizedBox(height: 12),
              const Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: ['Wifi','AC','Breakfast included','Parking','Gym','Spa','Pool'].map((k) => FilterChip(label: Text(k), selected: _houseAmenities[k] ?? false, onSelected: (v) => setState(() => _houseAmenities[k] = v))).toList()),
              const SizedBox(height: 12),
              const Text('Guests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _hotelGuestsCount = (_hotelGuestsCount - 1).clamp(1, 10))), Text('$_hotelGuestsCount'), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _hotelGuestsCount = (_hotelGuestsCount + 1).clamp(1, 10)))]),
              const SizedBox(height: 12),
              const Text('Check-in / Check-out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () async { final picked = await _pickDateRange(context, initial: _hotelDateRange); if (picked != null) setState(() => _hotelDateRange = picked); }, child: Text(_hotelDateRange==null ? 'Select dates' : '${_hotelDateRange!.start.toLocal().toString().split(' ')[0]} → ${_hotelDateRange!.end.toLocal().toString().split(' ')[0]}')),
              const SizedBox(height: 12),
              const Text('Sort by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
  child: DropdownButton<String>(
  value: safeVal(_sortOption, ['Relevance', 'Price', 'Rating', 'Distance']),
    isExpanded: true,
    underline: Container(),
    items: const [
      DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
      DropdownMenuItem(value: 'Price', child: Text('Price')),
      DropdownMenuItem(value: 'Rating', child: Text('Rating')),
      DropdownMenuItem(value: 'Distance', child: Text('Distance')),
    ],
    onChanged: (v) => setState(() => _sortOption = v ?? 'Relevance'),
  ),
)
            ],
          );

        case Category.car:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pickup location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)), child: DropdownButton<String>(value: _locationOptions.contains(_locationText) ? _locationText : _locationOptions.first, isExpanded: true, underline: Container(), items: _locationOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _locationText = v ?? _locationOptions.first))),
              const SizedBox(height: 12),
              const Text('Pickup date & time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () async { final dt = await _pickDateTime(context, initial: _pickupDateTime); if (dt != null) setState(() => _pickupDateTime = dt); }, child: Text(_pickupDateTime == null ? 'Select pickup' : _pickupDateTime!.toLocal().toString())),
              const SizedBox(height: 12),
              const Text('Drop-off date & time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () async { final dt = await _pickDateTime(context, initial: _dropoffDateTime); if (dt != null) setState(() => _dropoffDateTime = dt); }, child: Text(_dropoffDateTime == null ? 'Select drop-off' : _dropoffDateTime!.toLocal().toString())),
              const SizedBox(height: 12),
              const Text('Price range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RangeSlider(values: _pricePerDay, min: 0, max: 10000, divisions: 100, labels: RangeLabels('₹${_pricePerDay.start.toInt()}', '₹${_pricePerDay.end.toInt()}'), onChanged: (r) => setState(() => _pricePerDay = r)),
              const SizedBox(height: 12),
              const Text('Car type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['Hatchback','Sedan','SUV','Luxury'].map((c) => ChoiceChip(label: Text(c), selected: _carType==c, onSelected: (_) => setState(() => _carType=c))).toList()),
              const SizedBox(height: 12),
              const Text('Fuel type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['Petrol','Diesel','Electric'].map((f) => ChoiceChip(label: Text(f), selected: _fuelType==f, onSelected: (_) => setState(() => _fuelType=f))).toList()),
              const SizedBox(height: 12),
              const Text('Transmission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['Manual','Automatic'].map((t) => ChoiceChip(label: Text(t), selected: _transmission==t, onSelected: (_) => setState(() => _transmission=t))).toList()),
              const SizedBox(height: 12),
              const Text('Seating capacity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _seatingCapacity = (_seatingCapacity - 1).clamp(1, 12))), Text('$_seatingCapacity'), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _seatingCapacity = (_seatingCapacity + 1).clamp(1, 12)))]),
              const SizedBox(height: 12),
              const Text('Sort by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
  child: DropdownButton<String>(
  value: safeVal(_sortOption, ['Relevance', 'Price', 'Rating', 'Distance']),
    isExpanded: true,
    underline: Container(),
    items: const [
      DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
      DropdownMenuItem(value: 'Price', child: Text('Price')),
      DropdownMenuItem(value: 'Rating', child: Text('Rating')),
      DropdownMenuItem(value: 'Distance', child: Text('Distance')),
    ],
    onChanged: (v) => setState(() => _sortOption = v ?? 'Relevance'),
  ),
)

            ],
          );

        case Category.hourly:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)), child: DropdownButton<String>(value: _locationOptions.contains(_locationText) ? _locationText : _locationOptions.first, isExpanded: true, underline: Container(), items: _locationOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _locationText = v ?? _locationOptions.first))),
              const SizedBox(height: 12),
              const Text('Price per hour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RangeSlider(values: _pricePerHour, min: 0, max: 1000, divisions: 100, labels: RangeLabels('₹${_pricePerHour.start.toInt()}', '₹${_pricePerHour.end.toInt()}'), onChanged: (r) => setState(() => _pricePerHour = r)),
              const SizedBox(height: 12),
              const Text('Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [2,4,6,12].map((d) => ChoiceChip(label: Text('${d} hrs'), selected: _hourlyDurationHours==d, onSelected: (_) => setState(() => _hourlyDurationHours=d))).toList()),
              const SizedBox(height: 12),
              const Text('Guest capacity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _capacity = (_capacity - 1).clamp(1, 50))), Text('$_capacity'), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _capacity = (_capacity + 1).clamp(1, 50)))]),
              const SizedBox(height: 12),
              const Text('Room type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: safeVal(_roomType, ['Any', 'Standard', 'Deluxe']),
                items: const [
                  DropdownMenuItem(value: 'Any', child: Text('Any')),
                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'Deluxe', child: Text('Deluxe')),
                ],
                onChanged: (v) => setState(() => _roomType = v ?? 'Any'),
              ),
              const SizedBox(height: 12),
              const Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['AC','Wifi','Parking','TV'].map((k) => FilterChip(label: Text(k), selected: _houseAmenities[k] ?? false, onSelected: (v) => setState(() => _houseAmenities[k] = v))).toList()),
              const SizedBox(height: 12),
              const Text('Availability time slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: safeVal(_timeSlot, ['Morning', 'Afternoon', 'Evening', 'Night']),
                items: const [
                  DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                  DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                  DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                  DropdownMenuItem(value: 'Night', child: Text('Night')),
                ],
                onChanged: (v) => setState(() => _timeSlot = v ?? 'Morning'),
              ),
const SizedBox(height: 12),
const Text('Sort by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
const SizedBox(height: 8),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
  child: DropdownButton<String>(
  value: safeVal(_sortOption, ['Relevance', 'Price', 'Rating', 'Distance']),
    isExpanded: true,
    underline: Container(),
    items: const [
      DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
      DropdownMenuItem(value: 'Price', child: Text('Price')),
      DropdownMenuItem(value: 'Rating', child: Text('Rating')),
      DropdownMenuItem(value: 'Distance', child: Text('Distance')),
    ],
    onChanged: (v) => setState(() => _sortOption = v ?? 'Relevance'),
  ),
),
            ],
          );

          case Category.flights:
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('From'),
      DropdownButton<String>(
        value: safeVal(_departureCity, _locationOptions),
        isExpanded: true,
        items: _locationOptions
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _departureCity = v ?? _locationOptions.first),
      ),

      const SizedBox(height: 12),

      const Text('To'),
      DropdownButton<String>(
        value: safeVal(_arrivalCity, _locationOptions),
        isExpanded: true,
        items: _locationOptions
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _arrivalCity = v ?? (_locationOptions.length > 1 ? _locationOptions[1] : _locationOptions.first)),
      ),

      const SizedBox(height: 12),

      const Text('Travel Date'),
      OutlinedButton(
        onPressed: () async {
          final picked = await _pickDateTime(context, initial: _departureDate);
          if (picked != null) setState(() => _departureDate = picked);
        },
        child: Text(
          _departureDate == null
              ? 'Select date'
              : _departureDate!.toLocal().toString().split(' ')[0],
        ),
      ),

      const SizedBox(height: 12),

      const Text('Return Date'),
      OutlinedButton(
        onPressed: () async {
          final picked = await _pickDateTime(context, initial: _returnDate);
          if (picked != null) setState(() => _returnDate = picked);
        },
        child: Text(
          _returnDate == null
              ? 'Select return date'
              : _returnDate!.toLocal().toString().split(' ')[0],
        ),
      ),

      const SizedBox(height: 12),

      const Text('Airline'),
      DropdownButton<String>(
        value: safeVal(_selectedAirline, _airlines),
        isExpanded: true,
        items: _airlines
            .map((a) => DropdownMenuItem(value: a, child: Text(a)))
            .toList(),
        onChanged: (v) => setState(() => _selectedAirline = v ?? _airlines.first),
      ),

      const SizedBox(height: 12),

      const Text('Stops'),
      DropdownButton<String>(
        value: safeVal(_stopsOption, ['Any', 'Non-stop', '1 Stop', '2+ Stops']),
        items: const [
          DropdownMenuItem(value: 'Any', child: Text('Any')),
          DropdownMenuItem(value: 'Non-stop', child: Text('Non-stop')),
          DropdownMenuItem(value: '1 Stop', child: Text('1 Stop')),
          DropdownMenuItem(value: '2+ Stops', child: Text('2+ Stops')),
        ],
        onChanged: (v) => setState(() => _stopsOption = v ?? 'Any'),
      ),

      const SizedBox(height: 12),

      const Text('Class'),
      DropdownButton<String>(
        value: safeVal(_flightClass, ['Economy', 'Business', 'First']),
        items: const [
          DropdownMenuItem(value: 'Economy', child: Text('Economy')),
          DropdownMenuItem(value: 'Business', child: Text('Business')),
          DropdownMenuItem(value: 'First', child: Text('First')),
        ],
        onChanged: (v) => setState(() => _flightClass = v ?? 'Economy'),
      ),

      const SizedBox(height: 12),

      const Text('Price Range'),
      RangeSlider(
        values: _flightPriceRange,
        min: 0,
        max: 100000,
        divisions: 100,
        labels: RangeLabels(
          '₹${_flightPriceRange.start.toInt()}',
          '₹${_flightPriceRange.end.toInt()}',
        ),
        onChanged: (v) => setState(() => _flightPriceRange = v),
      ),
    ],
  );



  case Category.all:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RangeSlider(values: _priceRange, min: 0, max: 10000, divisions: 100, labels: RangeLabels('₹${_priceRange.start.toInt()}', '₹${_priceRange.end.toInt()}'), onChanged: (r) => setState(() => _priceRange = r)),
              const SizedBox(height: 12),
              const Text('Max Distance (km)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Slider(value: _maxDistance, min: 0, max: 500, divisions: 50, label: '${_maxDistance.toInt()} km', onChanged: (v) => setState(() => _maxDistance = v)),
              const SizedBox(height: 12),
              const Text('Minimum Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Slider(value: _minRating, min: 0, max: 5, divisions: 5, label: _minRating.toStringAsFixed(1), onChanged: (v) => setState(() => _minRating = v)),
              const SizedBox(height: 12),
              const Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: List.generate(amenitiesKeys.length, (i) { final key = amenitiesKeys[i]; return FilterChip(label: Text(key), selected: _amenities[key] ?? false, onSelected: (v) => setState(() => _amenities[key] = v), backgroundColor: Colors.white, selectedColor: AppColors.primary.withAlpha(50)); })),
              const SizedBox(height: 12),
              const Text('Property Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _propertyTypes.keys.map((k) { return FilterChip(label: Text(k), selected: _propertyTypes[k] ?? false, onSelected: (v) => setState(() => _propertyTypes[k] = v), backgroundColor: Colors.white, selectedColor: AppColors.primary.withAlpha(50)); }).toList()),
            ],
          );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: buildCategoryBody(),
                ),
              ),

              const SizedBox(height: 16),

              // Optional: sort control (shown for 'all' category)
              if (cat == Category.all) ...[
                const Text(
                  'Sort By',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
child: DropdownButton<String>(
  value: safeVal(_sortOption, ['Relevance', 'Price', 'Rating', 'Distance']),
  isExpanded: true,
  underline: Container(),
  items: const [
    DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
    DropdownMenuItem(value: 'Price', child: Text('Price')),
    DropdownMenuItem(value: 'Rating', child: Text('Rating')),
    DropdownMenuItem(value: 'Distance', child: Text('Distance')),
  ],
  onChanged: (v) => setState(() => _sortOption = v ?? 'Relevance'),
)



                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Reset', style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}