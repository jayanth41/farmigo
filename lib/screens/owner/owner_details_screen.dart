import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OwnerDetailsScreen extends StatefulWidget {
  const OwnerDetailsScreen({super.key});

  @override
  State<OwnerDetailsScreen> createState() => _OwnerDetailsScreenState();
}

class _OwnerDetailsScreenState extends State<OwnerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyNameController = TextEditingController();
  final _propertyAddressController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _upiController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();

  bool _saving = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _propertyNameController.dispose();
    _propertyAddressController.dispose();
    _ownerPhoneController.dispose();
    _upiController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Owner Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _propertyNameController,
                decoration: const InputDecoration(labelText: 'Property Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Property name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _propertyAddressController,
                decoration: const InputDecoration(labelText: 'Property Address'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Property address is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerPhoneController,
                decoration: const InputDecoration(labelText: 'Owner Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone is required';
                  final cleaned = v.replaceAll(RegExp(r'\D'), '');
                  if (cleaned.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _upiController,
                decoration: const InputDecoration(labelText: 'UPI ID (optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankAccountController,
                decoration: const InputDecoration(labelText: 'Bank Account Number (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ifscController,
                decoration: const InputDecoration(labelText: 'IFSC Code (optional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _onSubmit,
                  child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to complete owner details')));
      return;
    }

    setState(() => _saving = true);

    final ownerDetails = {
      'propertyName': _propertyNameController.text.trim(),
      'propertyAddress': _propertyAddressController.text.trim(),
      'ownerPhone': _ownerPhoneController.text.trim(),
      'upiId': _upiController.text.trim(),
      'bankAccount': _bankAccountController.text.trim(),
      'ifsc': _ifscController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'ownerDetails': ownerDetails,
        'isOwnerProfileComplete': true,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner details saved')));
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Failed to save owner details: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save owner details')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
