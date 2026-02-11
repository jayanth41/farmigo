import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';

class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Razorpay _razorpay;

  // Razorpay keys (you can change later)
  static const String _razorpayTestKey = 'rzp_test_1234567890';
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
  bool isEditingProfile = false;

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
    var options = {
      'key': _razorpayKey,
      'amount': 10000, // ₹100 in paise (test)
      'name': 'Skybase',
      'description': defaultPaymentId == null ? 'Add & set default payment' : 'Add Payment Method',
      'prefill': {
        'contact': phoneCtrl.text,
        'email': _auth.currentUser?.email,
      },
      'notes': {'defaultAfterAdd': defaultPaymentId == null},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Razorpay error: $e')),
      );
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
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

  void _handleRazorpayError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleRazorpayWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet used: ${response.walletName}')),
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
    _tabController = TabController(length: 4, vsync: this);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayWallet);
    _loadProfile();
  }

  @override
  void dispose() {
    _razorpay.clear();
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
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isEditingProfile ? Icons.check : Icons.edit),
            tooltip: isEditingProfile ? 'Save & lock' : 'Edit profile',
            onPressed: () async {
              if (isEditingProfile) {
                await _saveProfile();
              }
              setState(() => isEditingProfile = !isEditingProfile);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Notifications'),
            Tab(text: 'Payment'),
            Tab(text: 'Security'),
          ],
        ),
      ),
      body: loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildNotificationsTab(),
                _buildPaymentTab(),
                _buildSecurityTab(),
              ],
            ),
    );
  }

  // ================= PROFILE TAB =================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            readOnly: !isEditingProfile,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: phoneCtrl,
            readOnly: !isEditingProfile,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              suffixIcon: enable2FA
                  ? const Icon(Icons.verified, color: Colors.green)
                  : const Icon(Icons.verified_outlined),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: bioCtrl,
            readOnly: !isEditingProfile,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: 16),
          const Text('Business Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: businessNameCtrl,
            readOnly: !isEditingProfile,
            decoration: const InputDecoration(labelText: 'Business Name (Optional)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: businessAddrCtrl,
            readOnly: !isEditingProfile,
            decoration: const InputDecoration(labelText: 'Business Address'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isEditingProfile ? _saveProfile : null,
            child: const Text('Save Changes'),
          ),
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

  // ================= PAYMENT TAB =================
  Widget _buildPaymentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Payment Methods',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _openRazorpayCheckout,
            icon: const Icon(Icons.add_card),
            label: const Text('Add Card / UPI'),
          ),
        ),
        const SizedBox(height: 12),

        // ---- LIST OF CARDS (MULTIPLE) ----
        if (paymentMethods.isEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: const ListTile(
              leading: Icon(Icons.credit_card_outlined),
              title: Text('No payment methods saved'),
              subtitle: Text('Tap Add Card / UPI to add one'),
            ),
          )
        else
          AnimatedList(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: paymentMethods.length,
            itemBuilder: (context, index, animation) {
              final m = paymentMethods[index];
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(0.2, 0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOut)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildPaymentMethodCard(m),
                ),
              );
            },
          ),

        const SizedBox(height: 20),
        const Text('Payout Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.sync_alt),
            title: const Text('Automatic Payouts'),
            subtitle: const Text('Automatically transfer earnings to your bank'),
            trailing: Switch(
              value: autoPayout,
              onChanged: (v) {
                setState(() => autoPayout = v);
                _savePreferences();
              },
            ),
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