import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FiltersScreen extends StatefulWidget {
  final RangeValues priceRange;
  final double maxDistance;
  final bool luxuryOnly;
  final double minRating;
  final Map<String, bool> amenities;
  final Map<String, bool> propertyTypes;
  final String sortOption;

  const FiltersScreen({
    super.key,
    required this.priceRange,
    required this.maxDistance,
    required this.luxuryOnly,
    required this.minRating,
    required this.amenities,
  this.propertyTypes = const {},
    required this.sortOption,
  });

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late RangeValues _priceRange;
  late double _maxDistance;
  late bool _luxuryOnly;
  late double _minRating;
  late Map<String, bool> _amenities;
  late Map<String, bool> _propertyTypes;
  late String _sortOption;

  @override
  void initState() {
    super.initState();
    _priceRange = widget.priceRange;
    _maxDistance = widget.maxDistance;
    _luxuryOnly = widget.luxuryOnly;
    _minRating = widget.minRating;
    _amenities = Map.from(widget.amenities);
    // initialize property types with defaults if none provided
    if (widget.propertyTypes.isNotEmpty) {
      _propertyTypes = Map.from(widget.propertyTypes);
    } else {
      final defaults = ['Farmhouse', 'Villa', 'Hotel', 'Apartment', 'Cottage', 'Homestay'];
      _propertyTypes = {for (var k in defaults) k: false};
    }
    _sortOption = widget.sortOption;
  }

  @override
  Widget build(BuildContext context) {
    final amenitiesKeys = _amenities.keys.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters', style: TextStyle(color: Colors.black)),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Price range
              const Text('Price range'),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 10000,
                divisions: 100,
                labels: RangeLabels('₹${_priceRange.start.toInt()}', '₹${_priceRange.end.toInt()}'),
                onChanged: (r) => setState(() => _priceRange = r),
              ),
              const SizedBox(height: 8),

              // 2. Rating
              const Text('Minimum rating'),
              Slider(value: _minRating, min: 0, max: 5, divisions: 5, label: _minRating.toStringAsFixed(1), onChanged: (v) => setState(() => _minRating = v)),
              const SizedBox(height: 8),

              // 3. Amenities
              const Text('Amenities'),
              Wrap(
                spacing: 8,
                children: List.generate(amenitiesKeys.length, (i) {
                  final key = amenitiesKeys[i];
                  return FilterChip(label: Text(key), selected: _amenities[key] ?? false, onSelected: (v) => setState(() => _amenities[key] = v));
                }),
              ),
              const SizedBox(height: 12),

              // 4. Property type
              const Text('Property type'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _propertyTypes.keys.map((k) {
                  return FilterChip(label: Text(k), selected: _propertyTypes[k] ?? false, onSelected: (v) => setState(() => _propertyTypes[k] = v));
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Other optional filters
              const Text('Max distance (km)'),
              Slider(
                value: _maxDistance,
                min: 1,
                max: 200,
                divisions: 199,
                label: '${_maxDistance.toInt()} km',
                onChanged: (v) => setState(() => _maxDistance = v),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Luxury only'),
                Switch(value: _luxuryOnly, onChanged: (v) => setState(() => _luxuryOnly = v)),
              ]),
              const SizedBox(height: 12),
              const Text('Sort by'),
              DropdownButton<String>(
                value: _sortOption,
                items: const [
                  DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
                  DropdownMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
                  DropdownMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
                  DropdownMenuItem(value: 'Distance', child: Text('Distance')),
                  DropdownMenuItem(value: 'Rating', child: Text('Rating')),
                ],
                onChanged: (v) => setState(() => _sortOption = v ?? 'Relevance'),
              ),
              const Spacer(),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'priceRange': _priceRange,
                        'maxDistance': _maxDistance,
                        'luxuryOnly': _luxuryOnly,
                        'minRating': _minRating,
                        'amenities': _amenities,
                        'propertyTypes': _propertyTypes,
                        'sortOption': _sortOption,
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Apply'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _priceRange = const RangeValues(0, 10000);
                        _maxDistance = 100;
                        _luxuryOnly = false;
                        _minRating = 0;
                        _amenities.updateAll((key, value) => false);
                        _propertyTypes.updateAll((key, value) => false);
                        _sortOption = 'Relevance';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ])
            ],
          ),
        ),
      ),
    );
  }
}
