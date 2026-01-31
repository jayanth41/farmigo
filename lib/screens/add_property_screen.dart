import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
// theme-aware: use Theme.of(context) colors instead of AppColors
import '../controllers/app_location_controller.dart';
import 'owner_properties_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    // Try to prefill the location from the app-wide location controller exactly once.
    // Defensive: If the provider is not available, silently continue.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final locCtrl = Provider.of<AppLocationController>(context, listen: false);
        // If permission is not granted, inform the user (non-blocking).
        if (!locCtrl.isPermissionGranted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission not granted')));
        }

        // If we already have a friendly location name, use it to prefill the field.
        if (locCtrl.locationName.isNotEmpty && locCtrl.locationName != 'Fetching location...' && locCtrl.locationName != 'Location unavailable') {
          _location.text = locCtrl.locationName;
        }
      } catch (_) {
        // Provider not present or other error — ignore to keep behavior unchanged.
      }
    });
  }

  Future<void> _saveProperty() async {
    final title = _title.text.trim();
    final location = _location.text.trim();
    final priceText = _price.text.trim();
    final description = _description.text.trim();

    if (title.isEmpty || location.isEmpty || priceText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final priceValue = int.tryParse(priceText);
    if (priceValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price')));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
        setState(() => _loading = false);
        return;
      }

      final Map<String, dynamic> payload = {
        'owner_id': user.id,
        'title': title,
        'location': location,
        'price': priceValue,
        'description': description,
      };

      // If the app location provider is available and has coordinates, save them too
      // as separate fields (lat, lng) to remain backward compatible with existing
      // schema that expects a string `location`.
      try {
        final locCtrl = Provider.of<AppLocationController>(context, listen: false);
        if (locCtrl.latitude != null && locCtrl.longitude != null) {
          payload['lat'] = locCtrl.latitude;
          payload['lng'] = locCtrl.longitude;
        }
      } catch (_) {
        // Provider not available — ignore.
      }

      final res = await Supabase.instance.client.from('properties').insert(payload).select();

      debugPrint('AddProperty result: $res');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property added successfully')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerPropertiesScreen()),
      );
    } catch (e) {
      debugPrint('SAVE ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save property')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 8),
            TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _loading ? null : _saveProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                        )
                      : const Text('Save Property'),
                ),
            ),
          ],
        ),
      ),
    );
  }
}

