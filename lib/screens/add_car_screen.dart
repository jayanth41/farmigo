import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Car Details
  final TextEditingController _carNameController = TextEditingController();
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _kmDrivenController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();

  String _carCategory = 'SUV';
  String _fuelType = 'Petrol';
  String _transmission = 'Automatic';
  bool _driverAvailable = false;

  // Pricing
  final TextEditingController _pricePerDayController = TextEditingController();
  final TextEditingController _pricePerHourController = TextEditingController();
  final TextEditingController _weekendPriceController = TextEditingController();
  final TextEditingController _minHoursController = TextEditingController();
  final TextEditingController _driverChargeController = TextEditingController();

  // Location
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Photos
  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  // Amenities
  final Map<String, bool> _amenities = {
    'Air Conditioning': false,
    'GPS': false,
    'Bluetooth': false,
    'Reverse Camera': false,
    'Insurance Included': false,
    'Sunroof': false,
    'ABS Brakes': false,
  };

  @override
  void dispose() {
    _carNameController.dispose();
    _numberPlateController.dispose();
    _kmDrivenController.dispose();
    _seatsController.dispose();
    _pricePerDayController.dispose();
    _pricePerHourController.dispose();
    _weekendPriceController.dispose();
    _minHoursController.dispose();
    _driverChargeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(
            images.whereType<XFile>().map((img) => File(img.path)),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking photos: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitCar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Upload photos
      final List<String> photoUrls = [];
      for (int i = 0; i < _selectedPhotos.length; i++) {
        final file = _selectedPhotos[i];
        final ref = fb_storage.FirebaseStorage.instance
            .ref()
            .child('cars/${user.uid}/photo_$i.jpg');

        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        photoUrls.add(url);
      }

      // Create car listing in Firestore
      final docRef = FirebaseFirestore.instance.collection('properties').doc();

      final carData = {
        'propertyId': docRef.id,
        'ownerId': user.uid,
        'propertyType': 'car',
        'carName': _carNameController.text.trim(),
        'carCategory': _carCategory,
        'numberPlate': _numberPlateController.text.trim().toUpperCase(),
        'kmDriven': int.parse(_kmDrivenController.text),
        'seats': int.parse(_seatsController.text),
        'fuelType': _fuelType,
        'transmission': _transmission,
        'driverAvailable': _driverAvailable,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'pricePerDay': double.parse(_pricePerDayController.text),
        'pricePerHour': _pricePerHourController.text.isEmpty
            ? 0
            : double.parse(_pricePerHourController.text),
        'weekendPrice': _weekendPriceController.text.isEmpty
            ? double.parse(_pricePerDayController.text)
            : double.parse(_weekendPriceController.text),
        'minHours': _minHoursController.text.isEmpty
            ? 1
            : int.parse(_minHoursController.text),
        'driverHourlyCharge': _driverChargeController.text.isEmpty
            ? 0
            : double.parse(_driverChargeController.text),
        'amenities': _amenities,
        'photoUrls': photoUrls,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isActive': true,
      };

      await docRef.set(carData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car listing published successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Car'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Details Section
                _buildSectionTitle('Car Details', ''),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _carNameController,
                  decoration: InputDecoration(
                    labelText: 'Car Name',
                    hintText: 'e.g., Toyota Fortuner',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Enter car name' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _carCategory,
                  decoration: InputDecoration(
                    labelText: 'Car Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['SUV', 'Sedan', 'Hatchback', 'EV', 'MUV', 'Luxury']
                      .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _carCategory = v ?? _carCategory),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _numberPlateController,
                  decoration: InputDecoration(
                    labelText: 'Number Plate',
                    hintText: 'e.g., DL01AB1234',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Enter number plate' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _seatsController,
                        decoration: InputDecoration(
                          labelText: 'Number of Seats',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Enter seats' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _kmDrivenController,
                        decoration: InputDecoration(
                          labelText: 'KM Driven',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Enter KM driven' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fuelType,
                        decoration: InputDecoration(
                          labelText: 'Fuel Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['Petrol', 'Diesel', 'Electric', 'Hybrid']
                            .map((fuel) => DropdownMenuItem(
                                value: fuel, child: Text(fuel)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _fuelType = v ?? _fuelType),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _transmission,
                        decoration: InputDecoration(
                          labelText: 'Transmission',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['Automatic', 'Manual']
                            .map((trans) => DropdownMenuItem(
                                value: trans, child: Text(trans)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _transmission = v ?? _transmission),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Driver Available'),
                  value: _driverAvailable,
                  onChanged: (v) => setState(() => _driverAvailable = v),
                ),

                const SizedBox(height: 20),

                // Location & Description
                _buildSectionTitle('Location & Description', ''),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'City/Area where car is located',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Enter location' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Tell customers about your car...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Pricing Section
                _buildSectionTitle('Pricing', ''),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pricePerDayController,
                        decoration: InputDecoration(
                          labelText: 'Price per Day (₹)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Enter daily price' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pricePerHourController,
                        decoration: InputDecoration(
                          labelText: 'Price per Hour (₹)',
                          hintText: 'Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _weekendPriceController,
                  decoration: InputDecoration(
                    labelText: 'Weekend Price per Day (₹)',
                    hintText: 'Leave empty to use daily price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minHoursController,
                        decoration: InputDecoration(
                          labelText: 'Min Hours',
                          hintText: '1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _driverChargeController,
                        decoration: InputDecoration(
                          labelText: 'Driver Charge/Hour (₹)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Amenities Section
                _buildSectionTitle('Amenities', ''),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenities.entries.map((entry) {
                    return FilterChip(
                      label: Text(entry.key),
                      selected: entry.value,
                      onSelected: (selected) {
                        setState(() => _amenities[entry.key] = selected);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Photos Section
                _buildSectionTitle('Photos', 'Add at least 1 photo'),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.photo_library, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to add photos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedPhotos.length} photo(s) added',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_selectedPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedPhotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedPhotos[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Submit Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitCar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publish Car'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}
