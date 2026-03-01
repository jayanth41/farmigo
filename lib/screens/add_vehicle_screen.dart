import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Screen for adding a new vehicle for car rental business
class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNameController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _yearController = TextEditingController();

  String _selectedTransmission = 'Automatic';
  String _selectedFuelType = 'Petrol';
  final List<String> _selectedAmenities = [];
  File? _vehicleImage;

  bool _isSubmitting = false;

  final List<String> _amenities = [
    'AC',
    'Heater',
    'Power Steering',
    'Airbags',
    'ABS',
    'Driver',
    'WiFi',
    'Phone Charger',
  ];

  final List<String> _transmissionTypes = ['Manual', 'Automatic'];
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Electric', 'CNG'];
  final List<String> _vehicleTypes = [
    'Sedan',
    'Hatchback',
    'SUV',
    'MUV',
    'Luxury',
    'Tempo',
    'Truck'
  ];

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehicleTypeController.dispose();
    _registrationNumberController.dispose();
    _pricePerDayController.dispose();
    _descriptionController.dispose();
    _manufacturerController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // This is a placeholder implementation
      // In production, uncomment the image_picker import and use:
      // final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      // if (image != null) {
      //   setState(() => _vehicleImage = File(image.path));
      // }
      
      debugPrint('[AddVehicleScreen] Image picker - to be implemented with image_picker package');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload feature coming soon')),
      );
    } catch (e) {
      debugPrint('[AddVehicleScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_vehicleImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Generate vehicle ID
      final vehicleId = FirebaseFirestore.instance
          .collection('vehicles')
          .doc()
          .id;

      // Prepare vehicle data
      final vehicleData = {
        'id': vehicleId,
        'ownerId': uid,
        'name': _vehicleNameController.text.trim(),
        'type': _vehicleTypeController.text.trim(),
        'registrationNumber': _registrationNumberController.text.trim(),
        'pricePerDay': double.parse(_pricePerDayController.text),
        'description': _descriptionController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'year': int.parse(_yearController.text),
        'transmission': _selectedTransmission,
        'fuelType': _selectedFuelType,
        'amenities': _selectedAmenities,
        'imageUrl': '', // Will be filled after upload if needed
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save vehicle to Firestore
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .set(vehicleData);

      debugPrint('[AddVehicleScreen] Vehicle added successfully: $vehicleId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added successfully!'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('[AddVehicleScreen] Error submitting vehicle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Basic Information
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _vehicleNameController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Name *',
                    hintText: 'e.g., Swift Dzire',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter vehicle name'
                      : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _vehicleTypeController.text.isEmpty
                            ? null
                            : _vehicleTypeController.text,
                        items: _vehicleTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(
                              () => _vehicleTypeController.text = v ?? '');
                        },
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Select vehicle type'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Year *',
                          hintText: '2024',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter year'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer *',
                    hintText: 'e.g., Maruti Suzuki',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter manufacturer'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _registrationNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number *',
                    hintText: 'e.g., TS09AB1234',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter registration number'
                      : null,
                ),
                const SizedBox(height: 24),

                // Section: Specifications
                const Text(
                  'Specifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTransmission,
                        items: _transmissionTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedTransmission = v ?? 'Automatic');
                        },
                        decoration: const InputDecoration(
                          labelText: 'Transmission',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedFuelType,
                        items: _fuelTypes
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedFuelType = v ?? 'Petrol');
                        },
                        decoration: const InputDecoration(
                          labelText: 'Fuel Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section: Pricing
                const Text(
                  'Pricing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _pricePerDayController,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Day (₹) *',
                    hintText: '2000',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter price'
                      : null,
                ),
                const SizedBox(height: 24),

                // Section: Amenities
                const Text(
                  'Amenities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenities
                      .map((amenity) => FilterChip(
                            label: Text(amenity),
                            selected: _selectedAmenities.contains(amenity),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAmenities.add(amenity);
                                } else {
                                  _selectedAmenities.remove(amenity);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),

                // Section: Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add details about your vehicle...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Section: Vehicle Image
                const Text(
                  'Vehicle Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (_vehicleImage != null)
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_vehicleImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _pickImage,
                        child: const Text('Change Image'),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _isSubmitting ? null : _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to upload vehicle image',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitVehicle,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Add Vehicle'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
