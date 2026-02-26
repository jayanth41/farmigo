import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/owner_onboarding_service.dart';
import '../widgets/snackbar_helper.dart';

/// Screen 2: Property Details Entry
/// Displays only if Screen 1 is complete AND no property details exist.
/// Collects comprehensive property information.
/// After completion: shows GREEN SCREEN, then proceeds to Screen 3
class OwnerOnboardingScreen2 extends StatefulWidget {
  const OwnerOnboardingScreen2({super.key});

  @override
  State<OwnerOnboardingScreen2> createState() => _OwnerOnboardingScreen2State();
}

class _OwnerOnboardingScreen2State extends State<OwnerOnboardingScreen2> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amenitiesController = TextEditingController();
  final _capacityController = TextEditingController();
  final _pricePerNightController = TextEditingController();

  bool _loading = false;
  late OwnerOnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _onboardingService = OwnerOnboardingService();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amenitiesController.dispose();
    _capacityController.dispose();
    _pricePerNightController.dispose();
    super.dispose();
  }

  Future<void> _submitScreen2() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showAppSnack(context, 'Please sign in to continue', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      // Save property details to Firestore
      await FirebaseFirestore.instance.collection('owners').doc(uid).update({
        'property_description': _descriptionController.text.trim(),
        'amenities': _amenitiesController.text.trim(),
        'capacity': int.tryParse(_capacityController.text.trim()) ?? 0,
        'price_per_night':
        double.tryParse(_pricePerNightController.text.trim()) ?? 0.0,
        'property_details_completed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark Screen 2 as completed
      await _onboardingService.markScreenCompleted('screen_2');
      await _onboardingService.markPropertyDetailsCompleted();

      if (!mounted) return;

      // Show green success screen
      _showSuccessScreen(
        'Property Details Added Successfully!',
        'Your property information has been saved. Now let\'s add your properties to the system.',
        onContinue: () {
          Navigator.of(context).pushReplacementNamed(
            '/owner/onboarding/screen3',
            arguments: {'fromScreen': 2},
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error in Screen 2: $e');
      showAppSnack(context, 'Error saving details: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSuccessScreen(
    String title,
    String message, {
    required VoidCallback onContinue,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green checkmark icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.green.shade700,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onContinue,
                    child: const Text(
                      'Continue to Step 3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details - Step 2 of 3'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Tell Us About Your Property',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Provide detailed information about your property to attract guests.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.66,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 30),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Property Description',
                  hintText: 'Describe your property in detail...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Description is required';
                  if ((value?.length ?? 0) < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amenities field
              TextFormField(
                controller: _amenitiesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Amenities (comma-separated)',
                  hintText: 'e.g., WiFi, Pool, Kitchen, Parking...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.local_offer),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please list some amenities';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Capacity field
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Guest Capacity',
                  hintText: 'Number of guests',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.group),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Capacity is required';
                  if (int.tryParse(value!) == null) return 'Enter a valid number';
                  if ((int.tryParse(value) ?? 0) <= 0) {
                    return 'Capacity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price field
              TextFormField(
                controller: _pricePerNightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price Per Night (₹)',
                  hintText: 'Enter price',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Price is required';
                  if (double.tryParse(value!) == null) return 'Enter a valid price';
                  if ((double.tryParse(value) ?? 0) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitScreen2,
                  child: _loading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    'Save & Continue to Step 3',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
