import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FiltersScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersApplied;
  final Map<String, dynamic> initialFilters;

  const FiltersScreen({
    super.key,
    required this.onFiltersApplied,
    required this.initialFilters,
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
    // Initialize from initial filters
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
  }

  void _applyFilters() {
    widget.onFiltersApplied({
      'priceRange': _priceRange,
      'maxDistance': _maxDistance,
      'luxuryOnly': _luxuryOnly,
      'minRating': _minRating,
      'amenities': _amenities,
      'propertyTypes': _propertyTypes,
      'sortOption': _sortOption,
    });
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final amenitiesKeys = _amenities.keys.toList();

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Price range
                      const Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 10000,
                        divisions: 100,
                        labels: RangeLabels(
                          '₹${_priceRange.start.toInt()}',
                          '₹${_priceRange.end.toInt()}',
                        ),
                        onChanged: (r) => setState(() => _priceRange = r),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Maximum distance
                      const Text(
                        'Max Distance (km)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _maxDistance,
                        min: 0,
                        max: 500,
                        divisions: 50,
                        label: '${_maxDistance.toInt()} km',
                        onChanged: (v) => setState(() => _maxDistance = v),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_maxDistance.toInt()} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Minimum rating
                      const Text(
                        'Minimum Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _minRating,
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: _minRating.toStringAsFixed(1),
                        onChanged: (v) => setState(() => _minRating = v),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              _minRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. Luxury only
                      const Text(
                        'Premium Properties',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Show luxury properties only (₹3500+)'),
                        value: _luxuryOnly,
                        onChanged: (v) => setState(() => _luxuryOnly = v ?? false),
                        dense: true,
                      ),
                      const SizedBox(height: 24),

                      // 5. Amenities
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(amenitiesKeys.length, (i) {
                          final key = amenitiesKeys[i];
                          return FilterChip(
                            label: Text(key),
                            selected: _amenities[key] ?? false,
                            onSelected: (v) => setState(() => _amenities[key] = v),
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _amenities[key] ?? false
                                  ? AppColors.primary
                                  : Colors.grey[700],
                              fontWeight: _amenities[key] ?? false
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // 6. Property type
                      const Text(
                        'Property Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _propertyTypes.keys.map((k) {
                          return FilterChip(
                            label: Text(k),
                            selected: _propertyTypes[k] ?? false,
                            onSelected: (v) => setState(() => _propertyTypes[k] = v),
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _propertyTypes[k] ?? false
                                  ? AppColors.primary
                                  : Colors.grey[700],
                              fontWeight: _propertyTypes[k] ?? false
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 7. Sort option
                      const Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _sortOption,
                          isExpanded: true,
                          underline: Container(),
                          items: const [
                            DropdownMenuItem(
                              value: 'Relevance',
                              child: Text('Relevance'),
                            ),
                            DropdownMenuItem(
                              value: 'Price: Low to High',
                              child: Text('Price: Low to High'),
                            ),
                            DropdownMenuItem(
                              value: 'Price: High to Low',
                              child: Text('Price: High to Low'),
                            ),
                            DropdownMenuItem(
                              value: 'Distance',
                              child: Text('Distance'),
                            ),
                            DropdownMenuItem(
                              value: 'Rating',
                              child: Text('Rating'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _sortOption = v ?? 'Relevance'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: AppColors.primary),
                      ),
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
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(color: Colors.white),
                      ),
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