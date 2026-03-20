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
  String? _mappedCategory; // what we will store in owners/{uid}/category
  bool _saving = false;

  final List<String> _cities = ['Hyderabad', 'Bengaluru', 'Mumbai', 'Chennai', 'Pune', 'Delhi'];
  final List<String> _propertyTypes = ['Farmhouse', 'Villa', 'Hotel', 'Hourly', 'Car'];

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
    final ownerRef = FirebaseFirestore.instance.collection('owners').doc(uid);

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

    if (_mappedCategory == null) {
      showAppSnack(context, 'Please select a valid property type', isError: true);
      setState(() => _saving = false);
      return;
    }

    try {
      await docRef.set(data, SetOptions(merge: true));
      // Store category for OwnerDashboard
      await ownerRef.set({
        'category': _mappedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 41, 70, 92)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 41, 70, 92), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 41, 70, 92), width: 2),
      ),
    );

    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
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
              const Center(
                child: Text(
                  'Owner Onboarding',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Let your property start earning today',
                  style: TextStyle(
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
                  decoration: inputDecoration.copyWith(labelText: 'Owner Full Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: phone,
                  decoration: inputDecoration.copyWith(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _emailController, decoration: inputDecoration.copyWith(labelText: 'Email (optional)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: inputDecoration.copyWith(labelText: 'City'),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  initialValue: _selectedCity,
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null || v.isEmpty ? 'Please select a city' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: inputDecoration.copyWith(labelText: 'Property Type'),
                  items: _propertyTypes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  initialValue: _selectedPropertyType,
                  onChanged: (v) {
                    setState(() {
                      _selectedPropertyType = v;
                      // Map UI label -> backend category
                      switch (v) {
                        case 'Farmhouse': _mappedCategory = 'farmhouse'; break;
                        case 'Villa': _mappedCategory = 'villa'; break;
                        case 'Hotel': _mappedCategory = 'hotel'; break;
                        case 'Hourly': _mappedCategory = 'hourly'; break;
                        case 'Car': _mappedCategory = 'car'; break;
                        default: _mappedCategory = null;
                      }
                    });
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Please select a property type' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  decoration: inputDecoration.copyWith(labelText: 'Tell us about yourself'),
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
