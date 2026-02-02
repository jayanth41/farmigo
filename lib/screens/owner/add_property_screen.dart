import 'package:flutter/material.dart';

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

  void _addMockPhoto() async {
    // Since project doesn't include a file-picker, allow the user to add a photo URL
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
  }

  void _onPublish() {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least 5 photos')),
      );
      return;
    }

    // Collect form data here (in a real app send to backend / Firestore).

    // For now show a success message and pop back to Owner Dashboard.
    // Return `true` to indicate success so the caller can refresh.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property published (mock)')));
    Navigator.of(context).pop(true);
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
                  value: _propertyType,
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

                // 5) Photos Upload
                _sectionTitle('Photos Upload', 'PNG/JPG up to 10MB. Minimum 5 photos'),
                GestureDetector(
                  onTap: _addMockPhoto,
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
                          Text('${_photos.length} photos added', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                if (_photos.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => Stack(
                        children: [
                          Container(width: 120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]), child: Center(child: Text('Photo ${i + 1}'))),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: InkWell(onTap: () => setState(() => _photos.removeAt(i)), child: const Icon(Icons.close, size: 18)),
                          )
                        ],
                      ),
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
                        onPressed: _onPublish,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Publish Property'),
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
