import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/snackbar_helper.dart';
import '../owner_dashboard.dart';

class OwnerVerificationScreen extends StatefulWidget {
  const OwnerVerificationScreen({super.key});

  @override
  State<OwnerVerificationScreen> createState() => _OwnerVerificationScreenState();
}

class _OwnerVerificationScreenState extends State<OwnerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _propertyNameCtrl = TextEditingController();
  final TextEditingController _propertyAddressCtrl = TextEditingController();
  String? _city;

  XFile? _documentFile;
  XFile? _idProofFile;
  final List<XFile?> _photoFiles = [null, null, null];

  final bool _isSubmitting = false;

  final List<String> _cities = const [
    'Hyderabad', 'Bengaluru', 'Mumbai', 'Chennai', 'Pune', 'Kolkata', 'Delhi'
  ];

  @override
  void dispose() {
    _propertyNameCtrl.dispose();
    _propertyAddressCtrl.dispose();
    super.dispose();
  }

  Future<XFile?> _pickImageWithChoice() async {
    final picker = ImagePicker();

    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(null),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return null;

    try {
      if (choice == 'gallery') {
        return await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      } else {
        return await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      return null;
    }
  }

  Future<String?> _uploadXFile(XFile file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final localFile = File(file.path);
      final uploadTask = ref.putFile(localFile);
      final snap = await uploadTask;
      return await snap.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    // Owner verification flow removed. Do not persist owner_verification data.
    if (!_formKey.currentState!.validate()) return;
    showAppSnack(context, 'Owner verification flow has been removed', isError: false);
    Navigator.of(context).pop();
  }

  String? _displayName(XFile? f) {
    if (f == null) return null;
    return f.name.isNotEmpty ? f.name : f.path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _propertyNameCtrl,
                decoration: const InputDecoration(labelText: 'Property Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _propertyAddressCtrl,
                decoration: const InputDecoration(labelText: 'Property Address'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _city,
                hint: const Text('Select city'),
                items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _city = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Select city' : null,
              ),
              const SizedBox(height: 16),

              const Text('Upload Property Document', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final f = await _pickImageWithChoice();
                      if (f != null) setState(() => _documentFile = f);
                    },
                    child: const Text('Choose file'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_displayName(_documentFile) ?? 'No file selected')),
                ],
              ),
              const SizedBox(height: 12),

              const Text('Upload Owner ID Proof', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final f = await _pickImageWithChoice();
                      if (f != null) setState(() => _idProofFile = f);
                    },
                    child: const Text('Choose file'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_displayName(_idProofFile) ?? 'No file selected')),
                ],
              ),
              const SizedBox(height: 12),

              const Text('Upload 3 Property Photos', style: TextStyle(fontWeight: FontWeight.w600)),
              Column(
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final f = await _pickImageWithChoice();
                            if (f != null) setState(() => _photoFiles[i] = f);
                          },
                          child: Text('Choose photo ${i + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_displayName(_photoFiles[i]) ?? 'No photo selected')),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('Submit for Verification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
