import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:reorderables/reorderables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/property_model.dart';
import 'owner_dashboard.dart';

import 'property_preview_screen.dart';

enum PaymentType { advance, full, payAtProperty }

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({
    super.key,
    this.propertyId,
    this.isEdit = false,
    this.existingData,
    // Backwards-compatible alias: some callers pass `existingProperty`.
    this.existingProperty,
  });
  final String? propertyId;
  final bool isEdit;
  final dynamic existingData;
  final dynamic existingProperty;
  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  // Helper to parse time strings like "2:00 PM" to TimeOfDay
  TimeOfDay? _parseTime(String time) {
    try {
      final format = time.toLowerCase();
      final isPM = format.contains('pm');
      final parts = format.replaceAll(RegExp('[^0-9:]'), '').split(':');
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

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
  // Advanced Pricing
  final TextEditingController _weekdayPriceController = TextEditingController();
  final TextEditingController _weekendPriceController = TextEditingController();
  // Dynamic pricing by person ranges
  List<Map<String, TextEditingController>> _personPricing = [
    {
      'min': TextEditingController(),
      'max': TextEditingController(),
      'weekday': TextEditingController(),
     'weekend': TextEditingController(),
    }
  ];
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
  // Timings (multiple check-in/check-out)
  List<Map<String, TextEditingController>> _timings = [
    {
      'checkIn': TextEditingController(),
      'checkOut': TextEditingController(),
    }
  ];
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
  final TextEditingController _customAmenityController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();

  // Photos (we'll keep a list of URLs/placeholder strings for the UI)
  final List<String> _photos = [];
  final List<XFile> _pickedFiles = [];
  XFile? _documentFile;
  bool _isPublishing = false;

  // Availability
  bool _activeListing = true;
  bool _eventsAllowed = false;
  bool _commissionAccepted = false;

  // Payment type state
  PaymentType _paymentType = PaymentType.full;

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    final draft = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'street': _streetController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'zip': _zipController.text,
      'bedrooms': _bedroomsController.text,
      'bathrooms': _bathroomsController.text,
      'guests': _guestsController.text,
      'rules': _rulesController.text,
      'propertyType': _propertyType,
      'amenities': _amenities,
      'eventsAllowed': _eventsAllowed,
      'paymentType': _paymentType.name,
      'commissionAccepted': _commissionAccepted,
      'activeListing': _activeListing,
    };

    await prefs.setString('property_draft', jsonEncode(draft));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('property_draft');

    if (data == null) return;

    final draft = jsonDecode(data);

    setState(() {
      _nameController.text = draft['name'] ?? '';
      _descriptionController.text = draft['description'] ?? '';
      _streetController.text = draft['street'] ?? '';
      _cityController.text = draft['city'] ?? '';
      _stateController.text = draft['state'] ?? '';
      _zipController.text = draft['zip'] ?? '';
      _bedroomsController.text = draft['bedrooms'] ?? '';
      _bathroomsController.text = draft['bathrooms'] ?? '';
      _guestsController.text = draft['guests'] ?? '';
      _rulesController.text = draft['rules'] ?? '';
      _propertyType = draft['propertyType'] ?? 'Farmhouse';
      _eventsAllowed = draft['eventsAllowed'] ?? false;
      _activeListing = draft['activeListing'] ?? true;
      _commissionAccepted = draft['commissionAccepted'] ?? false;
      final type = draft['paymentType'];
      if (type != null) {
        _paymentType = PaymentType.values.firstWhere(
          (e) => e.name == type,
          orElse: () => PaymentType.full,
        );
      }

      if (draft['amenities'] != null) {
        final map = Map<String, dynamic>.from(draft['amenities']);
        map.forEach((key, value) {
          if (_amenities.containsKey(key)) {
            _amenities[key] = value == true;
          }
        });
      }
    });
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('property_draft');
  }

  @override
  void initState() {
    super.initState();

    _loadDraft();

    if (widget.isEdit) {
      var src = widget.existingData ?? widget.existingProperty;
      // Defensive: some callers/pages accidentally forward a List or other
      // unexpected types. If a single-element List containing a Map is
      // provided, unwrap it. Otherwise, skip prefill for unsupported types.
      if (src is List && src.isNotEmpty && src.first is Map<String, dynamic>) {
        src = src.first as Map<String, dynamic>;
      }

      if (src != null) {
        try {
          if (src is Map<String, dynamic>) {
            _nameController.text = src['propertyName'] ?? src['name'] ?? '';
            _descriptionController.text = src['description'] ?? '';
            _streetController.text = src['street'] ?? '';
            _cityController.text = src['city'] ?? '';
            _stateController.text = src['state'] ?? '';
            _zipController.text = src['zip'] ?? '';
            _bedroomsController.text = (src['bedrooms'] ?? '').toString();
            _bathroomsController.text = (src['bathrooms'] ?? '').toString();
            _guestsController.text = (src['maxGuests'] ?? '').toString();

            _propertyType = src['propertyType'] ?? src['category'] ?? 'Farmhouse';

            // Prefill eventsAllowed
            _eventsAllowed = src['eventsAllowed'] ?? false;
            _commissionAccepted = src['commissionAccepted'] ?? false;
            final type = src['paymentType'];
            if (type != null) {
              _paymentType = PaymentType.values.firstWhere(
                (e) => e.name == type,
                orElse: () => PaymentType.full,
              );
            }
            _rulesController.text = src['rules'] ?? '';
            

            // Amenities: some documents store amenities as a Map (name->bool)
            // while others store a List of amenity names. Handle both cases.
            final amenRaw = src['amenities'];
            if (amenRaw is Map) {
              final amenities = Map<String, dynamic>.from(amenRaw);
              amenities.forEach((key, value) {
                if (_amenities.containsKey(key)) {
                  _amenities[key] = value == true;
                }
              });
            } else if (amenRaw is List) {
              for (final a in amenRaw) {
                if (a is String && _amenities.containsKey(a)) {
                  _amenities[a] = true;
                }
              }
            }

            // Photos (existing URLs): accept a List or a single string
            final photosRaw = src['photoUrls'];
            if (photosRaw is List) {
              try {
                _photos.addAll(List<String>.from(photosRaw));
              } catch (_) {}
            } else if (photosRaw is String) {
              _photos.add(photosRaw);
            }
          } else if (src is PropertyModel) {
            _nameController.text = src.name;
            _descriptionController.text = src.description;
            _streetController.text = '';
            _cityController.text = src.city;
            _stateController.text = src.state;
            _zipController.text = '';
            _bedroomsController.text = src.bedrooms.toString();
            _bathroomsController.text = src.bathrooms.toString();
            _guestsController.text = src.maxGuests.toString();

            _propertyType = src.category;
            _photos.addAll(src.imageUrls);
            for (final k in _amenities.keys.toList()) {
              _amenities[k] = src.amenities.contains(k);
            }
          } else {
            // Unsupported / unexpected src type — log for debugging but don't crash.
            debugPrint('[AddPropertyScreen] Unexpected existing data type: ${src.runtimeType}');
          }
        } catch (e, st) {
          debugPrint('[AddPropertyScreen] Prefill failed: $e');
          debugPrint('[AddPropertyScreen] src runtimeType: ${src.runtimeType}');
          // Avoid crashing the widget; continue with empty form.
        }
      }
    }
  }

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
    _seatsController.dispose();
    _plateController.dispose();
    _kmController.dispose();
    _weekdayPriceController.dispose();
    _weekendPriceController.dispose();
    _customAmenityController.dispose();
    _rulesController.dispose();
    for (var p in _personPricing) {
     p['min']?.dispose();
     p['max']?.dispose();
     p['weekday']?.dispose();
     p['weekend']?.dispose();
  }
    for (var timing in _timings) {
      timing['checkIn']?.dispose();
      timing['checkOut']?.dispose();
    }
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

    if (!_commissionAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept 10% commission to continue')),
      );
      return;
    }

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
          bedrooms: _bedroomsController.text.trim(),
          bathrooms: _bathroomsController.text.trim(),
          guests: _guestsController.text.trim(),
          amenities: _amenities.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList(),
          photoCount: _photos.length + _pickedFiles.length,
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

    // Ensure at least one valid pricing range exists
    final hasValidRange = _personPricing.any((p) {
      final min = int.tryParse(p['min']?.text ?? '');
      final max = int.tryParse(p['max']?.text ?? '');
      final weekday = int.tryParse(p['weekday']?.text ?? '');
      final weekend = int.tryParse(p['weekend']?.text ?? '');

      return min != null &&
          max != null &&
          min < max &&
          weekday != null &&
          weekday > 0 &&
          weekend != null &&
          weekend > 0;
    });

    if (!hasValidRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one valid pricing range')),
      );
      setState(() => _isPublishing = false);
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

    Map<String, dynamic>? _stagedPending;

    // Convert timings to list of maps
    final List<Map<String, String>> timingsData = _timings.map((t) {
      return {
        'checkIn': t['checkIn']?.text ?? '',
        'checkOut': t['checkOut']?.text ?? '',
      };
    }).toList();

    // Validate timings (allow overnight, only block identical times)
    for (var t in timingsData) {
      if (t['checkIn']!.isNotEmpty && t['checkOut']!.isNotEmpty) {
        final checkIn = _parseTime(t['checkIn']!);
        final checkOut = _parseTime(t['checkOut']!);

        if (checkIn != null && checkOut != null) {
          final inMinutes = checkIn.hour * 60 + checkIn.minute;
          final outMinutes = checkOut.hour * 60 + checkOut.minute;

          // Allow overnight ranges (out < in means next day).
          // Only block identical times.
          if (outMinutes == inMinutes) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Check-in and Check-out cannot be the same')),
            );
            setState(() => _isPublishing = false);
            return;
          }
        }
      }
    }

    // Prevent duplicate timings
    final seen = <String>{};
    for (var t in timingsData) {
      final key = '${t['checkIn']}-${t['checkOut']}';
      if (seen.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate timings not allowed')),
        );
        setState(() => _isPublishing = false);
        return;
      }
      seen.add(key);
    }

    // Sort timings by check-in time
    timingsData.sort((a, b) {
      final t1 = _parseTime(a['checkIn'] ?? '');
      final t2 = _parseTime(b['checkIn'] ?? '');
      if (t1 == null || t2 == null) return 0;

      final m1 = t1.hour * 60 + t1.minute;
      final m2 = t2.hour * 60 + t2.minute;

      return m1.compareTo(m2);
    });

    // Prevent overlapping timings (including overnight)
    List<Map<String, int>> timingRanges = [];

    for (var t in timingsData) {
      final checkIn = _parseTime(t['checkIn'] ?? '');
      final checkOut = _parseTime(t['checkOut'] ?? '');

      if (checkIn == null || checkOut == null) continue;

      int start = checkIn.hour * 60 + checkIn.minute;
      int end = checkOut.hour * 60 + checkOut.minute;

      // Handle overnight (end < start → next day)
      if (end <= start) {
        end += 1440; // add 24 hours
      }

      timingRanges.add({'start': start, 'end': end});
    }

    // Compare all ranges
    for (int i = 0; i < timingRanges.length; i++) {
      for (int j = i + 1; j < timingRanges.length; j++) {
        final r1 = timingRanges[i];
        final r2 = timingRanges[j];

        final overlap = r1['start']! < r2['end']! && r2['start']! < r1['end']!;

        if (overlap) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timings should not overlap')),
          );
          setState(() => _isPublishing = false);
          return;
        }
      }
    }

    for (var p in _personPricing) {
      final min = int.tryParse(p['min']?.text ?? '');
      final max = int.tryParse(p['max']?.text ?? '');
      final weekday = int.tryParse(p['weekday']?.text ?? '');
      final weekend = int.tryParse(p['weekend']?.text ?? '');

      if (min == null ||
          max == null ||
          min >= max ||
          weekday == null ||
          weekday <= 0 ||
          weekend == null ||
          weekend <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all pricing ranges correctly')),
        );
        setState(() => _isPublishing = false);
        return;
      }
    }

    // Convert ranges for sorting & overlap check
    List<Map<String, int>> ranges = _personPricing.map((p) {
      return {
        'min': int.tryParse(p['min']?.text ?? '') ?? 0,
        'max': int.tryParse(p['max']?.text ?? '') ?? 0,
        'weekday': int.tryParse(p['weekday']?.text ?? '') ?? 0,
        'weekend': int.tryParse(p['weekend']?.text ?? '') ?? 0,
      };
    }).toList();

    // Sort ranges by min persons
    ranges.sort((a, b) => a['min']!.compareTo(b['min']!));

    // Prevent overlapping ranges
    for (int i = 0; i < ranges.length - 1; i++) {
      final current = ranges[i];
      final next = ranges[i + 1];

      if (current['max']! > next['min']!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person ranges should not overlap')),
        );
        setState(() => _isPublishing = false);
        return;
      }
    }

    final personPricingData = ranges;

    try {
      final firestore = FirebaseFirestore.instance;
      final storage = fb_storage.FirebaseStorage.instance;

      // Create property document as DRAFT for new properties, or prepare
      // to create a pending edit for existing properties. We don't apply
      // owner edits directly - they must go through admin approval.
      final docRef = widget.isEdit
          ? firestore.collection('properties').doc(widget.propertyId)
          : firestore.collection('properties').doc();
      final propertyId = docRef.id;

      if (!widget.isEdit) {
        // New property creation (same as before)
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
          'weekdayPrice': int.tryParse(_weekdayPriceController.text.trim()) ?? 0,
          'weekendPrice': int.tryParse(_weekendPriceController.text.trim()) ?? 0,
          'bedrooms': int.tryParse(_bedroomsController.text.trim()) ?? 0,
          'bathrooms': int.tryParse(_bathroomsController.text.trim()) ?? 0,
          'maxGuests': int.tryParse(_guestsController.text.trim()) ?? 0,
          'tierPricing': personPricingData,

          'propertyType': _propertyType,
          'carCategory': _propertyType == 'car' ? _carCategory : null,

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
          'rules': _rulesController.text.trim(),
          'activeListing': _activeListing,
          'eventsAllowed': _eventsAllowed,
          'timings': timingsData,
          'paymentType': _paymentType.name,
          'commissionAccepted': _commissionAccepted,

          // New listings start as draft; admin approves to make active
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
      }

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

        if (widget.isEdit) {
          // For edits, save the proposed changes under `pendingEdits`
          final Map<String, dynamic> pending = {
            'ownerId': uid,
            'propertyName': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'street': _streetController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
            'zip': _zipController.text.trim(),
            'lat': 0.0,
            'lng': 0.0,
            'weekdayPrice': int.tryParse(_weekdayPriceController.text.trim()) ?? 0,
            'weekendPrice': int.tryParse(_weekendPriceController.text.trim()) ?? 0,
            'bedrooms': int.tryParse(_bedroomsController.text.trim()) ?? 0,
            'bathrooms': int.tryParse(_bathroomsController.text.trim()) ?? 0,
            'maxGuests': int.tryParse(_guestsController.text.trim()) ?? 0,
            'propertyType': _propertyType,
            'carCategory': _propertyType == 'car' ? _carCategory : null,
            'carSeats': _propertyType == 'car'
                ? int.tryParse(_seatsController.text.trim()) ?? 0
                : null,
            'fuelType': _propertyType == 'car' ? _fuelType : null,
            'transmission': _propertyType == 'car' ? _transmission : null,
            'driverAvailable': _propertyType == 'car' ? _driverAvailable : null,
            'numberPlate': _propertyType == 'car' ? _plateController.text.trim() : null,
            'kmDriven': _propertyType == 'car' ? int.tryParse(_kmController.text.trim()) ?? 0 : null,
            'amenities': _amenities,
            'rules': _rulesController.text.trim(),
            'activeListing': _activeListing,
            'eventsAllowed': _eventsAllowed,
            'timings': timingsData,
            // include uploaded images/doc urls as part of pending edits
            'photoUrls': finalImageUrls,
            'documentUrl': documentUrl,
            'paymentType': _paymentType.name,
            'commissionAccepted': _commissionAccepted,
          };

          // keep a local copy so we can return it to callers
          _stagedPending = Map<String, dynamic>.from(pending);

          await docRef.update({
            'pendingEdits': pending,
            'editApprovalStatus': 'pending',
            'editRequestedAt': FieldValue.serverTimestamp(),
            'editRequestedBy': uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Final update — make property ACTIVE
          await docRef.update({
            'photoUrls': finalImageUrls,
            'documentUrl': documentUrl,
            'status': 'active',
            'publishedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
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

      // SUCCESS UI
      if (widget.isEdit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waiting for admin approval. Changes will be reviewed within 24 hours.'),
            duration: Duration(seconds: 5),
          ),
        );
        if (!mounted) return;
        // Return the staged pending-edits map to the caller so the
        // owner UI (or parent) can show a diff or navigate as needed.
        Navigator.of(context).pop(_stagedPending);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property published successfully'),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }

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
    return WillPopScope(
      onWillPop: () async {
        await _saveDraft();
        return true;
      },
      child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 10,
            16,
            16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  widget.isEdit ? 'Edit Property' : 'Add Property',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.isEdit
                      ? 'Update details and submit for admin approval'
                      : 'Don’t let your property sit idle — let it earn',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
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
                    border: Border.all(
                      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
                      width: 1,
                    ),
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
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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

// 3️⃣ Amenities
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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
            'Amenities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      const SizedBox(height: 20),

      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _amenities.keys.map((key) {
          final isSelected = _amenities[key] ?? false;
          return FilterChip(
            label: Text(key),
            selected: isSelected,
            onSelected: (val) {
              setState(() {
                _amenities[key] = val;
              });
            },
            selectedColor: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
            checkmarkColor: const Color.fromARGB(255, 41, 70, 92),
          );
        }).toList(),
      ),

      const SizedBox(height: 16),

      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customAmenityController,
              decoration: const InputDecoration(
                hintText: 'Add custom amenity',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final text = _customAmenityController.text.trim();
              if (text.isNotEmpty && !_amenities.containsKey(text)) {
                setState(() {
                  _amenities[text] = true;
                });
                _customAmenityController.clear();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ],
  ),
),

const SizedBox(height: 24),

// 4️⃣ Rules & Policies
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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
              '4',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Rules & Policies',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _rulesController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'e.g. No loud music after 10 PM, No smoking indoors, ID proof required...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 24),

// 5️⃣ Pricing & Capacity
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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
        ]),
        const SizedBox(height: 20),
        
        const SizedBox(height: 24),

SizedBox(
  width: double.infinity,
  child: Row(
    children: [
      const Text(
        'Pricing by Person Range',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _personPricing.add({
              'min': TextEditingController(),
              'max': TextEditingController(),
              'weekday': TextEditingController(),
              'weekend': TextEditingController(),
            });
          });
        },
      )
    ],
  ),
),

const SizedBox(height: 12),

..._personPricing.asMap().entries.map((entry) {
  int index = entry.key;
  var p = entry.value;

  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: p['min'],
              decoration: const InputDecoration(
                labelText: 'Min Persons',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: p['max'],
              decoration: const InputDecoration(
                labelText: 'Max Persons',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: p['weekday'],
                decoration: const InputDecoration(
                  labelText: 'Weekday Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: p['weekend'],
                decoration: const InputDecoration(
                  labelText: 'Weekend Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            if (_personPricing.length > 1)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    p['min']?.dispose();
                    p['max']?.dispose();
                    p['weekday']?.dispose();
                    p['weekend']?.dispose();
                    _personPricing.removeAt(index);
                  });
                },
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}).toList(),
      ],
    ],
  ),
),

const SizedBox(height: 24),

// 7️⃣ Property Document
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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

// 8️⃣ Timings
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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
              '8',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Timings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _timings.add({
                  'checkIn': TextEditingController(),
                  'checkOut': TextEditingController(),
                });
              });
            },
          )
        ],
      ),
      const SizedBox(height: 20),
      ..._timings.asMap().entries.map((entry) {
        int index = entry.key;
        var timing = entry.value;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: timing['checkIn'],
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Check-In',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        final formatted = picked.format(context);
                        setState(() {
                          timing['checkIn']!.text = formatted;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: timing['checkOut'],
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Check-Out',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        final formatted = picked.format(context);
                        setState(() {
                          timing['checkOut']!.text = formatted;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (_timings.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        timing['checkIn']?.dispose();
                        timing['checkOut']?.dispose();
                        _timings.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
      if (_timings.any((t) =>
          (t['checkIn']?.text.isNotEmpty ?? false) &&
          (t['checkOut']?.text.isNotEmpty ?? false))) ...[
        const SizedBox(height: 12),
        const Text(
          'Preview',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timings
              .where((t) =>
                  (t['checkIn']?.text.isNotEmpty ?? false) &&
                  (t['checkOut']?.text.isNotEmpty ?? false))
              .map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${t['checkIn']!.text} → ${t['checkOut']!.text}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ))
              .toList(),
        ),
      ],
    ],
  ),
),

const SizedBox(height: 24),

// 9️⃣ Photos Upload
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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
              '9',
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
      const SizedBox(height: 6),
      const Text(
        'Upload more to get attracted more ✨',
        style: TextStyle(
          color: Colors.black54,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
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
      const SizedBox(height: 16),
      // Photo preview grid with reorder and cover selection
      ReorderableWrap(
        spacing: 8,
        runSpacing: 8,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            final allImages = (_photos + _pickedFiles.map((e) => e.path).toList());
            if (oldIndex < _photos.length && newIndex < _photos.length) {
              // Both are in _photos list
              final item = _photos.removeAt(oldIndex);
              _photos.insert(newIndex, item);
            } else if (oldIndex >= _photos.length && newIndex >= _photos.length) {
              // Both are in _pickedFiles list
              final oldPickedIndex = oldIndex - _photos.length;
              final newPickedIndex = newIndex - _photos.length;
              final item = _pickedFiles.removeAt(oldPickedIndex);
              _pickedFiles.insert(newPickedIndex, item);
            } else if (oldIndex < _photos.length && newIndex >= _photos.length) {
              // From _photos to _pickedFiles
              final item = _photos.removeAt(oldIndex);
              _pickedFiles.insert(newIndex - _photos.length, XFile(item));
            } else if (oldIndex >= _photos.length && newIndex <= _photos.length) {
              // From _pickedFiles to _photos
              final item = _pickedFiles.removeAt(oldIndex - _photos.length);
              _photos.insert(newIndex, item.path);
            }
          });
        },
        children: List.generate(_photos.length + _pickedFiles.length, (index) {
          final isPicked = index >= _photos.length;
          final File? fileImage = isPicked
              ? File(_pickedFiles[index - _photos.length].path)
              : null;
          final String? networkImage = !isPicked
              ? _photos[index]
              : null;
          final isCover = index == 0;
          return Stack(
            key: ValueKey(index),
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCover ? Colors.green : Colors.grey.shade300,
                    width: isCover ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isPicked
                      ? Image.file(fileImage!, fit: BoxFit.cover)
                      : Image.network(networkImage!, fit: BoxFit.cover),
                ),
              ),
              // Cover badge
              if (isCover)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Cover',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              // Actions
              Positioned(
                top: 0,
                right: 0,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isPicked) {
                            final item = _pickedFiles.removeAt(index - _photos.length);
                            _pickedFiles.insert(0, item);
                          } else {
                            final item = _photos.removeAt(index);
                            _photos.insert(0, item);
                          }
                        });
                      },
                      child: const Icon(Icons.star, color: Colors.yellow),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isPicked) {
                            _pickedFiles.removeAt(index - _photos.length);
                          } else {
                            _photos.removeAt(index);
                          }
                        });
                      },
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    ],
  ),
),

const SizedBox(height: 24),
                

// 10️⃣ Availability Settings
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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
              '10',
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
        title: const Text('Active Listing'),
        value: _activeListing,
        onChanged: (v) => setState(() => _activeListing = v),
      ),
      SwitchListTile.adaptive(
        title: const Text('Events Allowed'),
        subtitle: const Text(
          'Allow parties/events at this property',
          style: TextStyle(fontSize: 12),
        ),
        value: _eventsAllowed,
        onChanged: (v) => setState(() => _eventsAllowed = v),
      ),
    ],
  ),
),


const SizedBox(height: 24),

// 11️⃣ Payment Options
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color.fromARGB(255, 41, 70, 92).withOpacity(0.2),
      width: 1,
    ),
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
              '11',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Payment Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 20),

      RadioListTile<PaymentType>(
        title: const Text('Advance Payment'),
        value: PaymentType.advance,
        groupValue: _paymentType,
        onChanged: (v) => setState(() => _paymentType = v!),
      ),
      RadioListTile<PaymentType>(
        title: const Text('Full Payment'),
        value: PaymentType.full,
        groupValue: _paymentType,
        onChanged: (v) => setState(() => _paymentType = v!),
      ),
      RadioListTile<PaymentType>(
        title: const Text('Pay at Property'),
        value: PaymentType.payAtProperty,
        groupValue: _paymentType,
        onChanged: (v) => setState(() => _paymentType = v!),
      ),

      const SizedBox(height: 12),

      CheckboxListTile(
        value: _commissionAccepted,
        onChanged: (v) => setState(() => _commissionAccepted = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'I agree to a 10% commission on each booking',
          style: TextStyle(fontSize: 13),
        ),
      ),
    ],
  ),
),
               
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await _clearDraft();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Draft cleared')),
                      );
                    },
                    child: const Text(
                      'Clear Draft',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _saveDraft();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPublishing ? null : _openPreview,
                    style: ElevatedButton.styleFrom(backgroundColor: widget.isEdit ? Colors.blue : Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isPublishing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(widget.isEdit ? 'Save Changes' : 'Publish Property'),
                  ),
                ),
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
              
// (Remove any car-specific pricing UI, e.g. Hourly Price field)