import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'owner/owner_details_screen.dart';

class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Razorpay plugin instance (optional). Nullable so we can safely handle
  // environments where initialization might fail.
  Razorpay? _razorpay;

  // Razorpay keys (you can change later)
  static const String _razorpayTestKey = 'rzp_test_REPLACE_WITH_YOUR_REAL_KEY';
  static const String _razorpayLiveKey = 'rzp_live_SBLnYIO8JTlM7O';
  static String get _razorpayKey => kDebugMode ? _razorpayTestKey : _razorpayLiveKey;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Profile controllers
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final businessNameCtrl = TextEditingController();
  final businessAddrCtrl = TextEditingController();

  // Security controllers
  final currentPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool loadingProfile = true;

  // Notification toggles
  bool notifyNewBooking = true;
  bool notifyConfirm = true;
  bool notifyCancel = true;
  bool notifyGuestMsg = true;
  bool notifyReviews = true;

  // Payment toggle
  bool autoPayout = true;

  // Security toggle
  bool enable2FA = false;

  Map<String, dynamic>? userData;
  // Store multiple payment methods locally
  List<Map<String, dynamic>> paymentMethods = [];
  String? defaultPaymentId;

  Future<void> _savePreferences() async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).set({
      'notifications': {
        'newBooking': notifyNewBooking,
        'confirm': notifyConfirm,
        'cancel': notifyCancel,
        'guestMsg': notifyGuestMsg,
        'reviews': notifyReviews,
      },
      'autoPayout': autoPayout,
      'enable2FA': enable2FA,
      'prefsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _openRazorpayCheckout() {
    debugPrint('[OwnerSettings] _openRazorpayCheckout called. kDebugMode=${kDebugMode}');
    // Razorpay SDK is not available on Web. Short-circuit and inform user.
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Razorpay is not supported on Web. Use Android/iOS device.'),
      ));
      debugPrint('[OwnerSettings] Aborting Razorpay checkout: running on Web');
      return;
    }

    // Prevent using dummy Razorpay key
    if (_razorpayKey.contains('1234567890') || _razorpayKey.contains('REPLACE')) {
      debugPrint('[OwnerSettings] ❌ Invalid Razorpay key used');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Razorpay key is invalid. Please use real test key.')),
      );
      return;
    }

    // Build options with defensive values and logging
    final contact = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '9999999999';
    final email = (_auth.currentUser?.email ?? '').isNotEmpty ? _auth.currentUser!.email! : 'test@example.com';

    final Map<String, dynamic> options = {
      'key': _razorpayKey,
      // amount must be in the smallest currency unit (paise) and an int
      'amount': (100 * 100), // 100 INR in paise
      'name': 'Skybase',
      'description': defaultPaymentId == null ? 'Add & set default payment' : 'Add Payment Method',
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'notes': {'defaultAfterAdd': defaultPaymentId == null},
    };

    debugPrint('[OwnerSettings] Razorpay options: $options');

    // Validation and warning before opening Razorpay
    if (contact.isEmpty || email.isEmpty) {
      debugPrint('[OwnerSettings] Invalid prefill data. contact=$contact email=$email');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing phone/email. Using default test values.')),
      );
    }

    try {
      // Ensure the plugin instance is available before calling into it. On
      // environments where initialization failed (or the plugin isn't present),
      // `_razorpay` may be null — avoid calling methods on a nullable receiver.
      if (_razorpay == null) {
        debugPrint('[OwnerSettings] Razorpay instance is null — cannot open checkout');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Razorpay is not initialized on this device')),
          );
        }
        return;
      }

      _razorpay!.open(options);
      debugPrint('[OwnerSettings] Razorpay.open() invoked');
    } catch (e, st) {
      debugPrint('[OwnerSettings] Razorpay.open() threw: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Razorpay error: ${e.toString()}')),
        );
      }
    }
  }

  // ignore: unused_element
  void _handleRazorpaySuccess(dynamic response) async {
    String? paymentId;
    try {
      paymentId = response?.paymentId;
    } catch (_) {
      try {
        paymentId = response['paymentId'] as String?;
      } catch (_) {
        paymentId = null;
      }
    }
    debugPrint('[OwnerSettings] Razorpay success: $paymentId');
    final uid = _auth.currentUser!.uid;

    final Map<String, dynamic> method = {
      'id': response.paymentId,
      'addedAt': FieldValue.serverTimestamp(),
      // Tag the method type (CARD by default since walletName isn't available in this response)
      'type': 'CARD',
    };

    final bool makeDefault = defaultPaymentId == null;

    await _firestore.collection('users').doc(uid).set({
      'paymentMethods': FieldValue.arrayUnion([method]),
      if (makeDefault) 'defaultPaymentId': method['id'],
    }, SetOptions(merge: true));

    setState(() {
      paymentMethods.add(method);
      if (makeDefault) defaultPaymentId = method['id'];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method added successfully')),
      );
    }
  }

  // ignore: unused_element
  void _handleRazorpayError(dynamic response) {
    var code;
    var message;
    try {
      code = response?.code;
      message = response?.message;
    } catch (_) {
      try {
        code = response['code'];
        message = response['message'];
      } catch (_) {
        code = null;
        message = response?.toString() ?? 'Unknown error';
      }
    }
    debugPrint('[OwnerSettings] Razorpay error: code=$code message=$message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: $message')),
    );
  }

  // ignore: unused_element
  void _handleRazorpayWallet(dynamic response) {
    String? walletName;
    try {
      walletName = response?.walletName;
    } catch (_) {
      try {
        walletName = response['walletName'] as String?;
      } catch (_) {
        walletName = null;
      }
    }
    debugPrint('[OwnerSettings] Razorpay external wallet used: $walletName');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet used: ${walletName ?? 'Unknown'}')),
    );
  }

  Future<void> _deletePaymentMethod(String id) async {
    final uid = _auth.currentUser!.uid;

    final toRemove = paymentMethods.firstWhere((e) => e['id'] == id, orElse: () => {});
    if (toRemove.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove payment method?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    await _firestore.collection('users').doc(uid).set({
      'paymentMethods': FieldValue.arrayRemove([toRemove]),
      if (defaultPaymentId == id) 'defaultPaymentId': FieldValue.delete(),
    }, SetOptions(merge: true));

    setState(() {
      paymentMethods.removeWhere((e) => e['id'] == id);
      if (defaultPaymentId == id) defaultPaymentId = null;
    });
  }

  Future<void> _setDefaultPayment(String id) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).set({
      'defaultPaymentId': id,
    }, SetOptions(merge: true));
    setState(() {
      defaultPaymentId = id;
    });
  }

  String? _verificationId;
  // ignore: unused_field
  bool _verifyingPhone = false;

  Future<void> _startPhoneVerification(String phone) async {
    setState(() => _verifyingPhone = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.currentUser!.linkWithCredential(credential);
        setState(() => enable2FA = true);
        await _savePreferences();
        setState(() => _verifyingPhone = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone verified automatically')),
          );
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _verifyingPhone = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.message}')),
        );
      },
      codeSent: (String verId, int? resendToken) {
        _verificationId = verId;
        setState(() => _verifyingPhone = false);
        _showOtpDialog();
      },
      codeAutoRetrievalTimeout: (String verId) {
        _verificationId = verId;
      },
    );
  }

  Future<void> _verifyOtp(String smsCode) async {
    if (_verificationId == null) return;
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    try {
      await _auth.currentUser!.linkWithCredential(credential);
      setState(() => enable2FA = true);
      await _savePreferences();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA enabled with phone')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  void _showOtpDialog() {
    final otpCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter OTP'),
        content: TextField(
          controller: otpCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '6-digit code'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => enable2FA = false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _verifyOtp(otpCtrl.text.trim());
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize Razorpay plugin and register handlers. This requires the
    // `razorpay_flutter` package to be present in pubspec.yaml and
    // `flutter pub get` to have been run.
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayWallet);
      debugPrint('[OwnerSettings] Razorpay initialized and handlers registered');
    } catch (e) {
      debugPrint('[OwnerSettings] Razorpay initialization failed: $e');
    }
    _loadProfile();
  }
  // (declaration moved earlier)

  @override
  void dispose() {
    try {
      // If the plugin instance exists, clear its handlers. This is a no-op
      // when `_razorpay` is null or does not implement `clear()`.
      _razorpay?.clear();
    } catch (_) {}
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      userData = doc.data();
      final pm = userData?['paymentMethods'];
      if (pm is List) {
        paymentMethods = pm.cast<Map<String, dynamic>>();
      }
      defaultPaymentId = userData?['defaultPaymentId'] as String?;
      final n = userData?['notifications'] as Map<String, dynamic>?;
      if (n != null) {
        notifyNewBooking = n['newBooking'] ?? true;
        notifyConfirm = n['confirm'] ?? true;
        notifyCancel = n['cancel'] ?? true;
        notifyGuestMsg = n['guestMsg'] ?? true;
        notifyReviews = n['reviews'] ?? true;
      }
      autoPayout = userData?['autoPayout'] ?? true;
      enable2FA = userData?['enable2FA'] ?? false;
      nameCtrl.text = userData?['name'] ?? '';
      phoneCtrl.text = userData?['phone'] ?? '';
      bioCtrl.text = userData?['bio'] ?? '';
      businessNameCtrl.text = userData?['businessName'] ?? '';
      businessAddrCtrl.text = userData?['businessAddress'] ?? '';
    }
    setState(() => loadingProfile = false);
  }

  // ignore: unused_element
  Future<void> _saveProfile() async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).set({
      'name': nameCtrl.text,
      'phone': phoneCtrl.text,
      'bio': bioCtrl.text,
      'businessName': businessNameCtrl.text,
      'businessAddress': businessAddrCtrl.text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _updatePassword() async {
    if (newPassCtrl.text != confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassCtrl.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 41, 70, 92),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '"Manage your account & preferences."',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Notifications'),
                  Tab(text: 'Security'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsTab(),
                _buildSecurityTab(),
              ],
            ),
    );
  }


  // ================= NOTIFICATIONS TAB =================
  Widget _buildNotificationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('New Booking Requests'),
                trailing: Switch(
                  value: notifyNewBooking,
                  onChanged: (v) {
                    setState(() => notifyNewBooking = v);
                    _savePreferences();
                  },
                ),
              ),
              ListTile(
                title: const Text('Booking Confirmations'),
                trailing: Switch(
                  value: notifyConfirm,
                  onChanged: (v) {
                    setState(() => notifyConfirm = v);
                    _savePreferences();
                  },
                ),
              ),
              ListTile(
                title: const Text('Cancellations'),
                trailing: Switch(
                  value: notifyCancel,
                  onChanged: (v) {
                    setState(() => notifyCancel = v);
                    _savePreferences();
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        const Text('Message Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Guest Messages'),
                trailing: Switch(
                  value: notifyGuestMsg,
                  onChanged: (v) {
                    setState(() => notifyGuestMsg = v);
                    _savePreferences();
                  },
                ),
              ),
              ListTile(
                title: const Text('Reviews'),
                trailing: Switch(
                  value: notifyReviews,
                  onChanged: (v) {
                    setState(() => notifyReviews = v);
                    _savePreferences();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildPaymentMethodCard(Map<String, dynamic> m) {
    final String id = m['id'] ?? '';
    final String type = m['type'] ?? 'CARD';
    final String last4 = id.length >= 4 ? id.substring(id.length - 4) : '----';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              child: Icon(type == 'CARD' ? Icons.credit_card : Icons.account_balance_wallet),
            ),
            if (defaultPaymentId == id)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.check_circle, color: Colors.green, size: 18),
              ),
          ],
        ),
        title: Text(type == 'CARD' ? 'Card ending in •••• $last4' : 'UPI / Wallet'),
        subtitle: Text(type),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(defaultPaymentId == id ? Icons.star : Icons.star_border),
              color: defaultPaymentId == id ? Colors.amber : null,
              onPressed: () => _setDefaultPayment(id),
              tooltip: 'Set default',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deletePaymentMethod(id),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SECURITY TAB =================
  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: currentPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
          const SizedBox(height: 8),
          TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
          const SizedBox(height: 8),
          TextField(controller: confirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _updatePassword, child: const Text('Update Password')),
          const SizedBox(height: 20),
          const Text('Two-Factor Authentication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('Enable 2FA (Phone OTP)'),
            subtitle: Text(enable2FA ? 'Active' : 'Not enabled'),
            trailing: Switch(
              value: enable2FA,
              onChanged: (v) async {
                if (!v) {
                  setState(() => enable2FA = false);
                  await _savePreferences();
                  return;
                }
                final phone = phoneCtrl.text.trim();
                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your phone in Profile tab first')),
                  );
                  return;
                }
                await _startPhoneVerification(phone);
              },
            ),
          ),
        ],
      ),
    );
  }
}