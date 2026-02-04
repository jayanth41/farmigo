import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'owner_dashboard.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
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
  final TextEditingController _minStayController = TextEditingController();

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
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip': _zipController.text.trim(),
        'pricePerNight': _priceController.text.trim(),
        'bedrooms': _bedroomsController.text.trim(),
        'bathrooms': _bathroomsController.text.trim(),
        'maxGuests': _guestsController.text.trim(),
        'minStay': _minStayController.text.trim(),
        'propertyType': _propertyType,
        'amenities': _amenities,
        'instantBooking': _instantBooking,
        'activeListing': _activeListing,
        'status': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Upload picked images
      final List<String> finalImageUrls = [];

for (int i = 0; i < _pickedFiles.length; i++) {
  final file = File(_pickedFiles[i].path);

  final filename =
      '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

  final ref = storage
      .ref()
      .child('properties/$uid/$propertyId/$filename');

  await ref.putFile(file);
  final url = await ref.getDownloadURL();

  finalImageUrls.add(url);
}


      // Add manually entered URLs too
      finalImageUrls.addAll(_photos);

      // Upload document if provided
      String? documentUrl;
      if (_documentFile != null) {
        final docRefStorage = storage.ref('properties/$propertyId/document/property_doc.jpg');

        final snap = await docRefStorage.putFile(File(_documentFile!.path));

        documentUrl = await snap.ref.getDownloadURL();
      }

      // Final update — make property ACTIVE
      await docRef.update({
        'photoUrls': finalImageUrls,
        'documentUrl': documentUrl,
        'status': 'active',
        'publishedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property published successfully')),
      );

      if (!mounted) return;
      // After successful publish, navigate to Owner Dashboard.
      try {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()));
      } catch (_) {
        Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Property'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fill in the details to list your property', style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 18),

                // 1) Basic Information
                _sectionTitle('Basic Information', ''),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Property Name', hintText: 'Luxury Farmhouse with Pool'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter property name' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _propertyType,
                  items: ['Farmhouse', 'Villa', 'Resort', 'Cottage', 'Room'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _propertyType = v ?? _propertyType),
                  decoration: const InputDecoration(labelText: 'Property Type'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                ),

                const SizedBox(height: 18),

                // 2) Location
                _sectionTitle('Location', ''),
                TextFormField(controller: _streetController, decoration: const InputDecoration(labelText: 'Street Address')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'State'))),
                ]),
                const SizedBox(height: 8),
                TextFormField(controller: _zipController, decoration: const InputDecoration(labelText: 'ZIP Code')),

                const SizedBox(height: 18),

                // 3) Pricing & Capacity
                _sectionTitle('Pricing & Capacity', ''),
                Row(children: [
                  Expanded(child: TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per Night'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _bedroomsController, decoration: const InputDecoration(labelText: 'Bedrooms'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextFormField(controller: _bathroomsController, decoration: const InputDecoration(labelText: 'Bathrooms'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _guestsController, decoration: const InputDecoration(labelText: 'Max Guests'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextFormField(controller: _minStayController, decoration: const InputDecoration(labelText: 'Minimum Stay (nights)'), keyboardType: TextInputType.number),

                const SizedBox(height: 18),

                // 4) Amenities
                _sectionTitle('Amenities', 'Select available amenities'),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _amenities.keys.map((k) {
                    return FilterChip(
                      label: Text(k),
                      selected: _amenities[k]!,
                      onSelected: (s) => setState(() => _amenities[k] = s),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Document selector (required)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(children: [
                    ElevatedButton(onPressed: _pickDocument, child: const Text('Select Property Document')),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_documentFile == null ? 'No document selected' : _documentFile!.name, overflow: TextOverflow.ellipsis)),
                  ]),
                ),

                // 5) Photos Upload
                _sectionTitle('Photos Upload', 'PNG/JPG up to 10MB. Minimum 1 photo'),
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
                          const Text('Click to upload or drag and drop', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text('${_photos.length + _pickedFiles.length} photos added', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                if (_photos.isNotEmpty || _pickedFiles.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length + _pickedFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        if (i < _photos.length) {
                          final photoUrl = _photos[i];
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset('assets/images/fallback_image.png')
,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: InkWell(onTap: () => setState(() => _photos.removeAt(i)), child: const Icon(Icons.close, size: 18)),
                              )
                            ],
                          );
                        } else {
                          final idx = i - _photos.length;
                          final file = _pickedFiles[idx];
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(file.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>const Icon(Icons.image_not_supported, size: 40)
,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: InkWell(onTap: () => setState(() => _pickedFiles.removeAt(idx)), child: const Icon(Icons.close, size: 18)),
                              )
                            ],
                          );
                        }
                      },
                    ),
                  ),

                const SizedBox(height: 18),

                // 6) Availability
                _sectionTitle('Availability Settings', ''),
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

                const SizedBox(height: 20),

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
                        onPressed: _isPublishing ? null : _onPublish,
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
