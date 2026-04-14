import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navigation/app_routes.dart';
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

  final List<String> _cities = [
    'Hyderabad',
    'Bengaluru',
    'Mumbai',
    'Chennai',
    'Pune',
    'Delhi',
    'Kolkata',
    'Ahmedabad',
    'Jaipur',
    'Surat',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Thane',
    'Bhopal',
    'Visakhapatnam',
    'Patna',
    'Vadodara',
    'Ghaziabad',
    'Ludhiana',
    'Agra',
    'Nashik',
    'Faridabad',
    'Meerut',
    'Rajkot',
    'Kalyan',
    'Vasai',
    'Varanasi',
    'Srinagar',
    'Aurangabad',
    'Dhanbad',
    'Amritsar',
    'Navi Mumbai',
    'Allahabad',
    'Ranchi',
    'Howrah',
    'Coimbatore',
    'Jabalpur',
    'Gwalior',
    'Vijayawada',
    'Jodhpur',
    'Madurai',
    'Raipur',
    'Kota',
    'Guwahati',
    'Chandigarh',
    'Solapur',
    'Hubli',
    'Tiruchirappalli',
    'Bareilly',
    'Mysuru',
    'Tiruppur',
    'Gurgaon',
    'Aligarh',
    'Jalandhar',
    'Bhubaneswar',
    'Salem',
    'Warangal',
    'Guntur',
    'Noida',
    'Dehradun'
  ];
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
                    onTap: () async {
                      final didPop = await Navigator.maybePop(context);
                      if (!didPop) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.home,
                          (route) => false,
                        );
                      }
                    },
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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number required';
                    }
                    final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (cleaned.length != 10) {
                      return 'Enter valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _emailController, decoration: inputDecoration.copyWith(labelText: 'Email (optional)')),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) {
                        String search = '';
                        List<String> filtered = List.from(_cities);

                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 16,
                                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Search city...',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    onChanged: (v) {
                                      setModalState(() {
                                        search = v.toLowerCase();
                                        filtered = _cities
                                            .where((c) => c.toLowerCase().contains(search))
                                            .toList();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 300,
                                    child: ListView.builder(
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) {
                                        return ListTile(
                                          title: Text(filtered[i]),
                                          onTap: () => Navigator.pop(context, filtered[i]),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );

                    if (selected != null) {
                      setState(() => _selectedCity = selected);
                    }
                  },
                  child: InputDecorator(
                    decoration: inputDecoration.copyWith(labelText: 'City'),
                    child: Text(
                      _selectedCity ?? 'Select city',
                      style: TextStyle(
                        color: _selectedCity == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
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
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () async {
                            final didPop = await Navigator.maybePop(context);
                            if (!didPop) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.home,
                                (route) => false,
                              );
                            }
                          },
                          child: const Text('Cancel'))),
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
