import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'owner_dashboard.dart';
import 'property_preview_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key, this.propertyId});
  final String? propertyId; // Optional: if provided, we can load existing data for editing (not implemented in this snippet)
  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  // STEP 1️⃣: Sync selected amenities to global "amenities" collection
  Future<void> _syncAmenitiesToGlobal(List<String> amenities) async {
    final collection = FirebaseFirestore.instance.collection('amenities');

    for (final amenity in amenities) {
      final normalized = amenity.trim().toLowerCase();
      final query = await collection
          .where('name', isEqualTo: amenity)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await collection.add({
          'name': amenity,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // STEP 1️⃣: Remove unused amenities from global collection
  Future<void> _cleanupUnusedAmenities() async {
    final firestore = FirebaseFirestore.instance;

    // Get all global amenities
    final amenitiesSnapshot = await firestore.collection('amenities').get();

    for (final amenityDoc in amenitiesSnapshot.docs) {
      final amenityName = amenityDoc['name'];

      // Check if any property contains this amenity as true
      final propertiesSnapshot = await firestore
          .collection('properties')
          .where('amenities.$amenityName', isEqualTo: true)
          .limit(1)
          .get();

      // If no property uses it → delete from global collection
      if (propertiesSnapshot.docs.isEmpty) {
        await amenityDoc.reference.delete();
      }
    }
  }
  final _formKey = GlobalKey<FormState>();

  // Basic Information
  final TextEditingController _nameController = TextEditingController();
  String _propertyType = 'Farmhouse';
  final TextEditingController _descriptionController = TextEditingController();

  // Location
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  // Pricing & Capacity
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();
  final TextEditingController _guestsController = TextEditingController();
  // Car-specific fields (extended)
final TextEditingController _seatsController = TextEditingController();
final TextEditingController _plateController = TextEditingController();
final TextEditingController _kmController = TextEditingController();
final String _fuelType = 'Petrol';
final String _transmission = 'Automatic';
final bool _driverAvailable = false;
// Car category
final String _carCategory = 'SUV';
  final TextEditingController _minStayController = TextEditingController();
  // Car booking
final TextEditingController _hourlyPriceController = TextEditingController();
  // Amenities
  final Map<String, bool> _amenities = {
    'WiFi': false,
    'Air Conditioning': false,
    'Parking': false,
    'Kitchen': false,
    'Pool': false,
    'Hot Tub': false,
    'Gym': false,
    'Pet Friendly': false,
    'Fireplace': false,
    'TV': false,
    'Washer & Dryer': false,
    'Garden': false,
  };

  // Photos (we'll keep a list of URLs/placeholder strings for the UI)
  final List<String> _photos = [];
  final List<XFile> _pickedFiles = [];
  XFile? _documentFile;
  bool _isPublishing = false;

  // Availability
  bool _instantBooking = false;
  bool _activeListing = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _guestsController.dispose();
    _minStayController.dispose();
    _seatsController.dispose();
    _plateController.dispose();
    _kmController.dispose();
    _hourlyPriceController.dispose();
    super.dispose();
  }

  void _addPhoto() async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Add Photo URL'),
            onTap: () => Navigator.of(ctx).pop('url'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pick from device'),
            onTap: () => Navigator.of(ctx).pop('picker'),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.of(ctx).pop(null),
          ),
        ]),
      ),
    );

    if (choice == 'url') {
      final urlController = TextEditingController();
      final ok = await showDialog<bool?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add Photo URL'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: 'https://...jpg or png'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add')),
          ],
        ),
      );

      if (ok == true && urlController.text.trim().isNotEmpty) {
        setState(() => _photos.add(urlController.text.trim()));
      }
    } else if (choice == 'picker') {
      try {
        final images = await ImagePicker().pickMultiImage(imageQuality: 85);
        if (images != null && images.isNotEmpty) {
          setState(() => _pickedFiles.addAll(images));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick images')));
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) setState(() => _documentFile = picked);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick document')));
    }
  }

  void _openPreview() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyPreviewScreen(
          propertyName: _nameController.text.trim(),
          propertyType: _propertyType,
          description: _descriptionController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zip: _zipController.text.trim(),
          pricePerNight: _priceController.text.trim(),
          bedrooms: _bedroomsController.text.trim(),
          bathrooms: _bathroomsController.text.trim(),
          guests: _guestsController.text.trim(),
          minStay: _minStayController.text.trim(),
          amenities: _amenities.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList(),
          photoCount: _photos.length + _pickedFiles.length,
          instantBooking: _instantBooking,
          activeListing: _activeListing,
          onConfirm: _onPublish,
        ),
      ),
    );
  }

  Future<void> _onPublish() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedFiles.isEmpty && _photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one property photo')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in required')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final storage = fb_storage.FirebaseStorage.instance;

      // Create property document as DRAFT
      final docRef = firestore.collection('properties').doc();
      final propertyId = docRef.id;

      await docRef.set({
        'ownerId': uid,
        'propertyName': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip': _zipController.text.trim(),

        // Location placeholders (can be updated later from a map picker)
        'lat': 0.0,
        'lng': 0.0,

        // Pricing & capacity as numbers (not strings)
        'pricePerNight': int.tryParse(_priceController.text.trim()) ?? 0,
        'bedrooms': int.tryParse(_bedroomsController.text.trim()) ?? 0,
        'bathrooms': int.tryParse(_bathroomsController.text.trim()) ?? 0,
        'maxGuests': int.tryParse(_guestsController.text.trim()) ?? 0,
        'minStay': int.tryParse(_minStayController.text.trim()) ?? 0,

        'propertyType': _propertyType,
        'carCategory': _propertyType == 'car' ? _carCategory : null,
        'hourlyPrice': _propertyType == 'car'
    ? int.tryParse(_hourlyPriceController.text.trim())
    : null,

        // Car-specific saved fields
'carSeats': _propertyType == 'car'
    ? int.tryParse(_seatsController.text.trim()) ?? 0
    : null,
'fuelType': _propertyType == 'car' ? _fuelType : null,
'transmission': _propertyType == 'car' ? _transmission : null,
'driverAvailable': _propertyType == 'car' ? _driverAvailable : null,
'numberPlate': _propertyType == 'car'
    ? _plateController.text.trim()
    : null,
'kmDriven': _propertyType == 'car'
    ? int.tryParse(_kmController.text.trim()) ?? 0
    : null,
        'amenities': _amenities,
        'instantBooking': _instantBooking,
        'activeListing': _activeListing,

        // Start as draft; will become active after images upload
        'status': 'draft',

        // Dashboard analytics defaults (VERY IMPORTANT)
        'rating': 0.0,
        'reviewCount': 0,
        'views': 0,
        'totalBookings': 0,

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // STEP 3️⃣: Sync selected amenities to global collection after property doc creation
      // Extract selected amenities
      final selectedAmenities = _amenities.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();

      // Sync to global amenities collection
      await _syncAmenitiesToGlobal(selectedAmenities);
      await _cleanupUnusedAmenities();

      // Upload picked images (robust: track uploaded refs so we can cleanup on failure)
      final List<String> finalImageUrls = [];
      final List<fb_storage.Reference> uploadedRefs = [];

      try {
        for (int i = 0; i < _pickedFiles.length; i++) {
          final file = File(_pickedFiles[i].path);
          final filename = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final ref = storage.ref().child('properties/$uid/$propertyId/$filename');

          final uploadTask = await ref.putFile(file);
          // keep reference for cleanup if needed
          uploadedRefs.add(uploadTask.ref);

          final url = await uploadTask.ref.getDownloadURL();
          finalImageUrls.add(url);
        }

        // Add manually entered URLs too
        finalImageUrls.addAll(_photos);

        // Upload document if provided
        String? documentUrl;
        if (_documentFile != null) {
          final docRefStorage = storage.ref('properties/$propertyId/document/property_doc.jpg');
          final snap = await docRefStorage.putFile(File(_documentFile!.path));
          uploadedRefs.add(snap.ref);
          documentUrl = await snap.ref.getDownloadURL();
        }

        // Final update — make property ACTIVE
        await docRef.update({
          'photoUrls': finalImageUrls,
          'documentUrl': documentUrl,
          'status': 'active',
          'publishedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (uploadError) {
        // Attempt cleanup of uploaded files to avoid orphaned storage items
        try {
          for (final r in uploadedRefs) {
            try {
              await r.delete();
            } catch (_) {
              // ignore deletion errors
            }
          }
        } catch (_) {}

        // Delete the draft document to avoid partial documents
        try {
          await docRef.delete();
        } catch (_) {}

        rethrow;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property published successfully')),
      );

      if (!mounted) return;
      // Return to the previous screen and signal success
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('Publish error: $e');
      debugPrint('STACKTRACE: $st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }


  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Property'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              '“Don’t let your property sit idle — let it earn.”',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EDF7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFB0CBE6)),
                  ),
                  child: const Text(
                    'Fill in the details to list your property',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1) Basic Information (Styled Card Layout)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 41, 70, 92),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text('Property Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter property name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter property name' : null,
                      ),

                      const SizedBox(height: 20),

                      const Text('Property Type *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _propertyType,
                        items: ['Farmhouse', 'Villa','Hotels','Hourly Rental']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => _propertyType = v ?? _propertyType),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Describe your property...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2) Location
                // 2️⃣ Location
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 41, 70, 92),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '2',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),

      const Text('Street Address *',
          style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _streetController,
        decoration: const InputDecoration(
          hintText: 'Enter street address',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      const SizedBox(height: 20),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('City *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    hintText: 'City',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('State *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    hintText: 'State',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 20),

      const Text('ZIP Code *',
          style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _zipController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'Enter ZIP code',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 24),

// 3️⃣ Pricing & Capacity
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 41, 70, 92),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Pricing & Capacity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),

      if (_propertyType != 'car') ...[
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Night *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _hourlyPriceController,
              decoration: const InputDecoration(
                labelText: 'Price per Hour (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _bedroomsController,
              decoration: const InputDecoration(
                labelText: 'Bedrooms *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _bathroomsController,
              decoration: const InputDecoration(
                labelText: 'Bathrooms *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _guestsController,
              decoration: const InputDecoration(
                labelText: 'Max Guests *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _minStayController,
              decoration: const InputDecoration(
                labelText: 'Min Stay (nights) *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
      ],
    ],
  ),
),

const SizedBox(height: 24),

// 5️⃣ Property Document
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 41, 70, 92),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '5',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Property Document',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: _pickDocument,
            icon: const Icon(Icons.description),
            label: const Text('Select Property Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 41, 70, 92),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _documentFile == null
                  ? 'No document selected'
                  : _documentFile!.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  ),
),

const SizedBox(height: 24),

// 6️⃣ Photos Upload
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 41, 70, 92),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '6',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Photos Upload',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'PNG/JPG up to 10MB. Minimum 1 photo',
        style: TextStyle(color: Colors.grey),
      ),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _addPhoto,
        child: DottedBorder(
          color: Colors.grey,
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: Container(
            width: double.infinity,
            height: 160,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.file_upload_outlined, size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('Click to upload or drag and drop',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  '${_photos.length + _pickedFiles.length} photos added',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 24),
                

                // 7️⃣ Availability Settings
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 41, 70, 92),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '7',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Availability Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 20),
      SwitchListTile.adaptive(
        title: const Text('Instant Booking'),
        value: _instantBooking,
        onChanged: (v) => setState(() => _instantBooking = v),
      ),
      SwitchListTile.adaptive(
        title: const Text('Active Listing'),
        value: _activeListing,
        onChanged: (v) => setState(() => _activeListing = v),
      ),
    ],
  ),
),

const SizedBox(height: 24),
               

                // Bottom actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isPublishing ? null : _openPreview,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: _isPublishing ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Publish Property'),
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
}

// Small DottedBorder replacement to avoid an external dependency. This
// renders a rounded rectangle with a dashed border using a custom painter.
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.dashPattern = const [4, 4],
    this.borderType = BorderType.RRect,
    this.radius = const Radius.circular(8),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashRectPainter(color: color, strokeWidth: strokeWidth, dashPattern: dashPattern, radius: radius),
      child: child,
    );
  }
}

enum BorderType { RRect }

class _DashRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final Radius radius;

  _DashRectPainter({required this.color, required this.strokeWidth, required this.dashPattern, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth;

    // Draw dashed path
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      int index = 0;
      while (distance < metric.length) {
        final len = dashPattern[index % dashPattern.length];
        final extracted = metric.extractPath(distance, distance + len);
        canvas.drawPath(extracted, paint);
        distance += len;
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
              