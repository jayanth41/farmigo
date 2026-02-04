import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/snackbar_helper.dart';
import 'add_property_screen.dart';

class OwnerOnboardingScreen extends StatefulWidget {
  const OwnerOnboardingScreen({super.key});

  @override
  State<OwnerOnboardingScreen> createState() => _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends State<OwnerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedCity;
  String? _selectedPropertyType;
  bool _saving = false;

  final List<String> _cities = ['Hyderabad', 'Bengaluru', 'Mumbai', 'Chennai', 'Pune', 'Delhi'];
  final List<String> _propertyTypes = ['Farmhouse', 'Villa', 'Resort', 'Cottage', 'Room'];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (uid == null) {
      showAppSnack(context, 'Please sign in to continue', isError: true);
      return;
    }

    setState(() => _saving = true);

    final docRef = FirebaseFirestore.instance.collection('owner_verification').doc(uid);

    final data = {
      'ownerName': _ownerNameController.text.trim(),
      'phone': phone,
      'email': _emailController.text.trim(),
      'city': _selectedCity,
      'propertyType': _selectedPropertyType,
      'bio': _bioController.text.trim(),
      'isOwnerDetailsSubmitted': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await docRef.set(data, SetOptions(merge: true));
      if (!mounted) return;
      showAppSnack(context, 'Owner details saved', isSuccess: true);
      // Navigate to AddPropertyScreen replacing current onboarding
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
    } catch (e) {
      debugPrint('Failed to save owner verification: $e');
      showAppSnack(context, 'Failed to save owner details', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Owner Onboarding')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(labelText: 'Owner Full Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(controller: TextEditingController(text: phone), decoration: const InputDecoration(labelText: 'Phone Number'), readOnly: true),
                const SizedBox(height: 12),
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email (optional)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'City'),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  value: _selectedCity,
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null || v.isEmpty ? 'Please select a city' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Property Type'),
                  items: _propertyTypes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  value: _selectedPropertyType,
                  onChanged: (v) => setState(() => _selectedPropertyType = v),
                  validator: (v) => v == null || v.isEmpty ? 'Please select a property type' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Tell us about yourself'),
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _saving ? null : _saveAndContinue,
                          child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Continue to Add Property'))),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}
