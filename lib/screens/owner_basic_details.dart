import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/snackbar_helper.dart';

class OwnerBasicDetailsScreen extends StatefulWidget {
  const OwnerBasicDetailsScreen({super.key});

  @override
  State<OwnerBasicDetailsScreen> createState() => _OwnerBasicDetailsScreenState();
}

class _OwnerBasicDetailsScreenState extends State<OwnerBasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _street = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _zip = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email.text = user.email ?? '';
      _phone.text = user.phoneNumber ?? '';
      _fullName.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _businessName.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isSaving = false);
      showAppSnack(context, 'You must be signed in', isError: true);
      return;
    }

    // Save the profile to the canonical users collection instead of owners.
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    final profile = {
      'fullName': _fullName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'businessName': _businessName.text.trim(),
      'street': _street.text.trim(),
      'city': _city.text.trim(),
      'state': _state.text.trim(),
      'zip': _zip.text.trim(),
    };

    final data = {'profile': profile};

    try {
      await userDoc.set(data, SetOptions(merge: true));
      if (!mounted) return;
      // Owner onboarding removed — return to previous screen.
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Failed to save owner basic details (saved to users): $e');
      showAppSnack(context, 'Failed to save details', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner - Basic Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tell us about yourself', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(controller: _fullName, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.trim().isEmpty ? 'Enter email' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _businessName, decoration: const InputDecoration(labelText: 'Business name')),
                const SizedBox(height: 12),
                const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(controller: _street, decoration: const InputDecoration(labelText: 'Street Address'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter street address' : null),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _state, decoration: const InputDecoration(labelText: 'State'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter state' : null))]),
                const SizedBox(height: 8),
                TextFormField(controller: _zip, decoration: const InputDecoration(labelText: 'ZIP Code'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter ZIP' : null),
                const SizedBox(height: 20),
                Row(children: [Expanded(child: OutlinedButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _isSaving ? null : _onSave, child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save and Continue')))]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
