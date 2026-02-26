import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/owner_onboarding_service.dart';
import '../widgets/snackbar_helper.dart';
import 'owner_onboarding_screen.dart';

/// Screen 1: User Not Owner
/// Displays when user is new and has NO onboarding data.
/// Collects basic user/farm information.
/// After completion: automatically proceeds to Screen 2
class OwnerOnboardingScreen1 extends StatefulWidget {
  const OwnerOnboardingScreen1({super.key});

  @override
  State<OwnerOnboardingScreen1> createState() => _OwnerOnboardingScreen1State();
}

class _OwnerOnboardingScreen1State extends State<OwnerOnboardingScreen1> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCity;
  String? _selectedPropertyType;
  bool _loading = false;

  final List<String> _cities = [
    'Hyderabad',
    'Bengaluru',
    'Mumbai',
    'Chennai',
    'Pune',
    'Delhi'
  ];
  final List<String> _propertyTypes = [
    'Farmhouse',
    'Villa',
    'Hotel',
    'Hourly',
    'Car'
  ];

  late OwnerOnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _onboardingService = OwnerOnboardingService();
    _prefillUserData();
  }

  void _prefillUserData() {
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitScreen1() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showAppSnack(context, 'Please sign in to continue', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      // Save basic information to Firestore
      await FirebaseFirestore.instance.collection('owners').doc(uid).set(
        {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'farm_name': _farmNameController.text.trim(),
          'location': _locationController.text.trim(),
          'city': _selectedCity,
          'property_type': _selectedPropertyType,
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Mark Screen 1 as completed
      await _onboardingService.markScreenCompleted('screen_1');

      // Update onboarding status to in_progress
      await _onboardingService.updateOnboardingStatus('in_progress');

      if (!mounted) return;

      // Show success and proceed to Screen 2
      showAppSnack(context, 'Basic details saved! Let\'s add property details.', isError: false);

      // Navigate to Screen 2
      Navigator.of(context).pushReplacementNamed(
        '/owner/onboarding/screen2',
        arguments: {'fromScreen': 1},
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error in Screen 1: $e');
      showAppSnack(context, 'Error saving details: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become an Owner - Step 1 of 3'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 20),
              Text(
                'Welcome to Farmigo!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Complete these steps once to set up your owner account.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.33,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 30),

              // Form fields
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Phone number is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Farm name field
              TextFormField(
                controller: _farmNameController,
                decoration: InputDecoration(
                  labelText: 'Property/Farm Name',
                  hintText: 'Enter your property name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.home),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Property name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location/Address',
                  hintText: 'Enter your property location',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Location is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City dropdown
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: _cities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCity = value);
                },
                validator: (value) {
                  if (value == null) return 'Please select a city';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Property type dropdown
              DropdownButtonFormField<String>(
                value: _selectedPropertyType,
                decoration: InputDecoration(
                  labelText: 'Property Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _propertyTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPropertyType = value);
                },
                validator: (value) {
                  if (value == null) return 'Please select a property type';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitScreen1,
                  child: _loading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    'Continue to Step 2',
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
