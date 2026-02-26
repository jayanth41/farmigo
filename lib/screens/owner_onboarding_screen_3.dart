import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/owner_onboarding_service.dart';
import '../widgets/snackbar_helper.dart';

/// Screen 3: Add Properties
/// Displays only if property details exist AND no properties are linked.
/// User adds properties to system.
/// After completion: shows GREEN SCREEN, then completes onboarding
class OwnerOnboardingScreen3 extends StatefulWidget {
  const OwnerOnboardingScreen3({super.key});

  @override
  State<OwnerOnboardingScreen3> createState() => _OwnerOnboardingScreen3State();
}

class _OwnerOnboardingScreen3State extends State<OwnerOnboardingScreen3> {
  final _formKey = GlobalKey<FormState>();
  final _propertyNameController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _addedProperties = [];
  late OwnerOnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _onboardingService = OwnerOnboardingService();
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _addProperty() {
    if (!_formKey.currentState!.validate()) return;

    final property = {
      'name': _propertyNameController.text.trim(),
      'bedrooms': int.tryParse(_bedroomsController.text.trim()) ?? 0,
      'bathrooms': int.tryParse(_bathroomsController.text.trim()) ?? 0,
      'area': int.tryParse(_areaController.text.trim()) ?? 0,
      'addedAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _addedProperties.add(property);
      _propertyNameController.clear();
      _bedroomsController.clear();
      _bathroomsController.clear();
      _areaController.clear();
    });

    showAppSnack(context, 'Property added! Add another or continue.', isError: false);
  }

  void _removeProperty(int index) {
    setState(() => _addedProperties.removeAt(index));
  }

  Future<void> _completeOnboarding() async {
    if (_addedProperties.isEmpty) {
      showAppSnack(context, 'Please add at least one property', isError: true);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showAppSnack(context, 'Please sign in to continue', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      // Save properties to Firestore
      await FirebaseFirestore.instance.collection('owners').doc(uid).update({
        'properties': _addedProperties,
        'onboarding_status': 'completed',
        'onboarding_completed': true,
        'owner_status': 'pending',
        'onboarding_submitted_at': FieldValue.serverTimestamp(),
        'verification_status': 'pending_verification',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark Screen 3 as completed and update onboarding status
      await _onboardingService.markScreenCompleted('screen_3');
      await _onboardingService.markPropertiesAdded();
      await _onboardingService.updateOnboardingStatus('completed');

      if (!mounted) return;

      // Show green success screen
      _showSuccessScreen(
        'Properties Added Successfully!',
        'Your properties have been saved. Your account is now pending developer verification.',
        onContinue: () {
          // Navigate to pending approval screen (NOT dashboard or onboarding)
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/owner_pending_approval',
            (route) => false,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error in Screen 3: $e');
      showAppSnack(context, 'Error saving properties: $e', isError: true);
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
                      'Go to Dashboard',
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
        title: const Text('Add Properties - Step 3 of 3'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Add Your Properties',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add the properties you want to list on Farmigo.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 1.0,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 30),

            // Form to add property
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _propertyNameController,
                    decoration: InputDecoration(
                      labelText: 'Property Name',
                      hintText: 'e.g., Green Valley Farmhouse',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.home),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Property name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bedroomsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Bedrooms',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.bed),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            if (int.tryParse(value!) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _bathroomsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Bathrooms',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.bathroom),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            if (int.tryParse(value!) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Area (sq. ft.)',
                      hintText: 'Enter area in square feet',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.straighten),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Area is required';
                      if (int.tryParse(value!) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addProperty,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Property'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // List of added properties
            if (_addedProperties.isNotEmpty) ...[
              Text(
                'Added Properties (${_addedProperties.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addedProperties.length,
                itemBuilder: (context, index) {
                  final prop = _addedProperties[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: Text(prop['name']),
                      subtitle: Text(
                        '${prop['bedrooms']} BR • ${prop['bathrooms']} BA • ${prop['area']} sq. ft.',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeProperty(index),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Complete button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _loading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Text(
                  'Complete Onboarding',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
