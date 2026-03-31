import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/favorites_controller.dart';
import 'package:image_picker/image_picker.dart' as img;
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userDoc;
  bool _loading = true;
  String _activeRole = 'user';
  late FavoritesController _favoritesController;
  // Real-time stats: we'll use StreamBuilders directly on Firestore collections/docs

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    _favoritesController = Get.find<FavoritesController>();
    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }
  // (No long-lived listeners here; StreamBuilders will subscribe/unsubscribe automatically.)

  @override
  Widget build(BuildContext context) {
    // avoid unused local warning — _auth.currentUser is accessed in helpers

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 41, 70, 92),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  // --- Settings-style layout with section titles and ListTile rows ---
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Account Settings",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: const Color.fromARGB(255, 41, 70, 92),
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      side: const BorderSide(color: Colors.white, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        ExpansionTile(
                          leading: const Icon(Icons.person_outline, color: Colors.white),
                          title: const Text(
                            "Edit Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.email_outlined, color: Colors.white),
                              title: const Text("Update Email", style: TextStyle(color: Colors.white)),
                              onTap: () async {
                                final controller = TextEditingController();
                                final result = await showDialog<String?>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Update Email"),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        hintText: "Enter new email",
                                        border: OutlineInputBorder(),
                                        enabledBorder: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                                        child: const Text("Update"),
                                      ),
                                    ],
                                  ),
                                );

                                if (result != null && result.isNotEmpty) {
                                  bool authUpdated = false;
                                  try {
                                    final current = _auth.currentUser;
                                    if (current != null) {
                                      // Attempt to update the auth email directly with dynamic
                                      // invocation for compatibility across firebase_auth
                                      // versions. If the method doesn't exist at runtime we
                                      // attempt the newer verifyBeforeUpdateEmail API and
                                      // fall back to an OTP re-auth flow if needed.
                                      try {
                                        await (current as dynamic).updateEmail(result);
                                        authUpdated = true;
                                      } on NoSuchMethodError catch (nsme) {
                                        debugPrint('updateEmail not found at runtime: $nsme');
                                        // Try the newer API and handle recent-login requirement.
                                        try {
                                          await (current as dynamic).verifyBeforeUpdateEmail(result);
                                          authUpdated = true;
                                        } on FirebaseAuthException catch (e) {
                                          debugPrint('verifyBeforeUpdateEmail failed: ${e.code}');
                                          if (e.code == 'requires-recent-login') {
                                            final phoneRaw = _userDoc?['phone'] as String? ?? _auth.currentUser?.phoneNumber;
                                            final phone = (phoneRaw ?? '').trim();

                                            if (phone.isNotEmpty) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Recent login required — sending OTP to your phone...')),
                                                );
                                              }

                                              final reauthOk = await _reauthWithPhoneOtp(phone);
                                              if (reauthOk) {
                                                try {
                                                  await (current as dynamic).verifyBeforeUpdateEmail(result);
                                                  authUpdated = true;
                                                } catch (e) {
                                                  debugPrint('verifyBeforeUpdateEmail retry after reauth failed: $e');
                                                  try {
                                                    await (current as dynamic).updateEmail(result);
                                                    authUpdated = true;
                                                  } catch (e) {
                                                    debugPrint('updateEmail retry after reauth failed: $e');
                                                    authUpdated = false;
                                                  }
                                                }
                                              } else {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Unable to re-authenticate via OTP. Please logout and login again.')),
                                                  );
                                                }
                                                authUpdated = false;
                                              }
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Please logout and login again before changing email.'),
                                                  ),
                                                );
                                              }
                                              authUpdated = false;
                                            }
                                          } else {
                                            authUpdated = false;
                                          }
                                        } catch (e) {
                                          debugPrint('verifyBeforeUpdateEmail fallback failed: $e');
                                          authUpdated = false;
                                        }
                                      } on FirebaseAuthException catch (e) {
                                        debugPrint('updateEmail failed: ${e.code}');

                                        if (e.code == 'requires-recent-login') {
                                          final phoneRaw = _userDoc?['phone'] as String? ?? _auth.currentUser?.phoneNumber;
                                          final phone = (phoneRaw ?? '').trim();

                                          if (phone.isNotEmpty) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Recent login required — sending OTP to your phone...')),
                                              );
                                            }

                                            final reauthOk = await _reauthWithPhoneOtp(phone);
                                            if (reauthOk) {
                                              try {
                                                await (current as dynamic).updateEmail(result);
                                                authUpdated = true;
                                              } on NoSuchMethodError catch (nsme) {
                                                debugPrint('updateEmail not found on retry: $nsme');
                                                try {
                                                  await (current as dynamic).verifyBeforeUpdateEmail(result);
                                                  authUpdated = true;
                                                } catch (e) {
                                                  debugPrint('verifyBeforeUpdateEmail retry failed: $e');
                                                  authUpdated = false;
                                                }
                                              } catch (e) {
                                                debugPrint('updateEmail retry after reauth failed: $e');
                                                authUpdated = false;
                                              }
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Unable to re-authenticate via OTP. Please logout and login again.')),
                                                );
                                              }
                                              authUpdated = false;
                                            }
                                          } else {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please logout and login again before changing email.',
                                                  ),
                                                ),
                                              );
                                            }
                                            authUpdated = false;
                                          }
                                        } else {
                                          authUpdated = false;
                                        }
                                      } catch (e) {
                                        debugPrint('updateEmail failed: $e');
                                        authUpdated = false;
                                      }
                                    }
                                  } catch (err) {
                                    debugPrint('updateEmail failed (auth): $err');
                                    authUpdated = false;
                                  }

                                  if (authUpdated) {
                                    try {
                                      await _firestore
                                          .collection('users')
                                          .doc(_auth.currentUser!.uid)
                                          .update({'email': result});

                                      await _loadUser();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Email updated successfully")),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('updateEmail succeeded but failed to update Firestore: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Email updated in auth but failed to save in profile')),
                                        );
                                      }
                                    }
                                  } else {
                                    final phoneRaw = _userDoc?['phone'] as String? ?? _auth.currentUser?.phoneNumber;
                                    await _showEmailUpdateRecoveryDialog(result, phoneRaw);
                                  }
                                }
                              },
                            ),
                            const Divider(height: 1, color: Colors.white),
                            ListTile(
                              leading: const Icon(Icons.phone_outlined, color: Colors.white),
                              title: const Text("Update Phone Number", style: TextStyle(color: Colors.white)),
                              onTap: () async {
                                final controller = TextEditingController();
                                final result = await showDialog<String?>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Update Phone Number"),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(hintText: "Enter phone number"),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                                        child: const Text("Update"),
                                      ),
                                    ],
                                  ),
                                );

                                if (result != null && result.isNotEmpty) {
                                  String phone = result.trim();

                                  // Remove spaces and dashes
                                  phone = phone.replaceAll(RegExp(r"[^0-9+]"), "");

                                  // If user entered 10 digit Indian number, convert to +91 format
                                  if (!phone.startsWith('+')) {
                                    if (phone.length == 10) {
                                      phone = '+91$phone';
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Enter valid 10 digit phone number")),
                                        );
                                      }
                                      return;
                                    }
                                  }

                                  try {
                                    await _auth.verifyPhoneNumber(
                                      phoneNumber: phone,
                                      verificationCompleted: (PhoneAuthCredential credential) async {
                                        // Auto verification (Android)
                                        await _firestore
                                            .collection('users')
                                            .doc(_auth.currentUser!.uid)
                                            .update({'phone': phone});

                                        await _loadUser();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Phone number updated")),
                                          );
                                        }
                                      },
                                      verificationFailed: (e) {
                                        debugPrint('Phone verification failed: $e');
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Phone verification failed")),
                                          );
                                        }
                                      },
                                      codeSent: (verificationId, resendToken) async {
                                        final codeController = TextEditingController();

                                        final smsCode = await showDialog<String?>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text("Enter OTP"),
                                            content: TextField(
                                              controller: codeController,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                hintText: "Enter OTP",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
                                                child: const Text("Verify"),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (smsCode == null || smsCode.isEmpty) return;

                                        final credential = PhoneAuthProvider.credential(
                                          verificationId: verificationId,
                                          smsCode: smsCode,
                                        );

                                        try {
                                          await _auth.signInWithCredential(credential);

                                          await _firestore
                                              .collection('users')
                                              .doc(_auth.currentUser!.uid)
                                              .update({'phone': phone});

                                          await _loadUser();

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Phone number updated")),
                                            );
                                          }
                                        } catch (e) {
                                          debugPrint('OTP verification failed: $e');
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Invalid OTP")),
                                            );
                                          }
                                        }
                                      },
                                      codeAutoRetrievalTimeout: (verificationId) {},
                                    );
                                  } catch (e) {
                                    debugPrint('verifyPhoneNumber error: $e');
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        // ---- Payment Methods section ----
                        if (_activeRole == 'owner') ...[
                          const Divider(height: 1, color: Colors.white),
                          ExpansionTile(
                            leading: const Icon(Icons.payment_outlined, color: Colors.white),
                            title: const Text(
                              "Payment Methods",
                              style: TextStyle(color: Colors.white),
                            ),
                            iconColor: Colors.white,
                            collapsedIconColor: Colors.white,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.credit_card, color: Colors.white),
                                title: const Text("Add Card", style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  _openRazorpayCheckout();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.account_balance_wallet, color: Colors.white),
                                title: const Text("Add UPI", style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  _openRazorpayCheckout();
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Account Actions",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      side: const BorderSide(color: Color.fromARGB(255, 41, 70, 92), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.red),
                          title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Delete Account"),
                                content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final uid = _auth.currentUser?.uid;
                              if (uid != null) {
                                await _firestore.collection('users').doc(uid).delete();
                                await _auth.currentUser?.delete();
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                }
                              }
                            }
                          },
                        ),
                        const Divider(height: 1, color: Color.fromARGB(255, 41, 70, 92)),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text("Logout"),
                          onTap: () async {
                            await _auth.signOut();
                            if (!mounted) return;
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _userDoc = null;
        _loading = false;
      });
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      _userDoc = doc.exists ? doc.data() : null;
      _activeRole = _userDoc?['activeRole'] ?? 'user';
    } catch (e) {
      debugPrint('Failed to load user doc: $e');
      _userDoc = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAndUploadImage(img.ImageSource source) async {
    final picker = img.ImagePicker();

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final file = File(pickedFile.path);

    try {
      final ref = fb_storage.FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(user.uid);

      await ref.putFile(file);

      final photoUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': photoUrl,
      });

      if (mounted) {
        setState(() {
          _userDoc?['photoUrl'] = photoUrl;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile photo updated")),
        );
      }
    } catch (e) {
      debugPrint("Profile photo upload failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload photo")),
        );
      }
    }
  }

  // Attempt to reauthenticate the current user using SMS OTP sent to the
  // phone number stored on the user's profile. Returns true when reauth
  // succeeded.
  Future<bool> _reauthWithPhoneOtp(String phone) async {
    if (phone.isEmpty) return false;

    final completer = Completer<bool>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.currentUser?.reauthenticateWithCredential(credential);
            if (!completer.isCompleted) completer.complete(true);
          } catch (e) {
            if (!completer.isCompleted) completer.complete(false);
          }
        },
        verificationFailed: (e) {
          debugPrint('Phone verification failed: $e');
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (verificationId, resendToken) async {
          // Ask user to enter the SMS code.
          if (!mounted) {
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          final codeController = TextEditingController();
          final smsCode = await showDialog<String?>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Enter OTP'),
              content: TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'SMS code'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, codeController.text.trim()), child: const Text('Verify')),
              ],
            ),
          );

          if (smsCode == null || smsCode.isEmpty) {
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          final cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
          try {
            await _auth.currentUser?.reauthenticateWithCredential(cred);
            if (!completer.isCompleted) completer.complete(true);
          } catch (e) {
            debugPrint('Reauth with SMS credential failed: $e');
            if (!completer.isCompleted) completer.complete(false);
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // If auto retrieval times out, we'll wait for manual code entry via codeSent dialog flow.
          if (!completer.isCompleted) {
            // do nothing here; completion happens in codeSent or verificationFailed
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('verifyPhoneNumber exception: $e');
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  // Show a recovery dialog with options to retry via OTP or logout & login.
  Future<void> _showEmailUpdateRecoveryDialog(String newEmail, String? phoneRaw) async {
    final phone = (phoneRaw ?? '').trim();

    if (!mounted) return;

    // The dialog returns when user picks an action; actions themselves perform work.
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Email Update Failed'),
          content: const Text(
            'Please verify by re-login to continue',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout? You can login again and then change your email.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx2, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx2, true);
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _auth.signOut();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              child: const Text('Logout'),
            ),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildProfileHeader() {
    final user = _auth.currentUser;
    final photoUrl = _userDoc?['photoUrl'] as String? ?? user?.photoURL;
    final displayName = _userDoc?['name'] as String? ?? user?.displayName ?? '';
    final email = _userDoc?['email'] as String? ?? user?.email ?? '';
    final phone = _userDoc?['phone'] as String? ?? user?.phoneNumber ?? '';

    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      displayName.isNotEmpty ? displayName[0] : 'U',
                      style: const TextStyle(fontSize: 36),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text("Take Photo"),
                              onTap: () async {
                                Navigator.pop(ctx);
                                await _pickAndUploadImage(img.ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text("Choose from Gallery"),
                              onTap: () async {
                                Navigator.pop(ctx);
                                await _pickAndUploadImage(img.ImageSource.gallery);
                              },
                            ),
                            if ((_userDoc?['photoUrl'] ?? '').toString().isNotEmpty)
                              ListTile(
                                leading: const Icon(Icons.delete_outline, color: Colors.red),
                                title: const Text(
                                  "Remove Photo",
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () async {
                                  Navigator.pop(ctx);

                                  final uid = _auth.currentUser?.uid;
                                  if (uid == null) return;

                                  await _firestore.collection('users').doc(uid).update({
                                    'photoUrl': null,
                                  });

                                  await _loadUser();
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 41, 70, 92),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName.isNotEmpty ? displayName : 'No name', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                _activeRole == 'user' ? 'User Account' : 'Owner Account',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              if (email.isNotEmpty) Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
              if (phone.isNotEmpty) Text(phone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCounter() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
        ],
      );
    }

    final uid = user.uid;
    final bookingsStream = _firestore.collection('users').doc(uid).collection('bookings').snapshots();
    final userDocStream = _firestore.collection('users').doc(uid).snapshots();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bookings
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: bookingsStream,
          builder: (context, snap) {
            final bookings = snap.hasData ? snap.data!.size : 0;
            return _buildStatItem("Bookings", bookings.toString());
          },
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white,
        ),
        // Favorites
        Obx(() {
          final favCount = _favoritesController.favorites.length;
          return _buildStatItem("Favorites", favCount.toString());
        }),
        Container(
          width: 1,
          height: 40,
          color: Colors.white,
        ),
        // Rewards
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream,
          builder: (context, snap) {
            int rewards = 0;
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data();
              final rp = data?['rewardPoints'];
              if (rp is int) {
                rewards = rp;
              } else if (rp is num) rewards = rp.toInt();
              else if (rp is String) rewards = int.tryParse(rp) ?? 0;
            }
            return _buildStatItem("Rewards", rewards.toString());
          },
        ),
      ],
    );
  }


  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // ---------------- EDIT FORM ----------------
  // (Previously an unused helper was here; removed to keep code clean.)

  // ---- Payment Methods Bottom Sheet ----
  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Payment Methods",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text("Add Card"),
                onTap: () {
                  Navigator.pop(context);
                  _openRazorpayCheckout();
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("Add UPI"),
                onTap: () {
                  Navigator.pop(context);
                  _openRazorpayCheckout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openRazorpayCheckout() {
    final options = {
      'key': 'rzp_test_xxxxxxxx',
      'amount': 100 * 100,
      'name': 'Skybase',
      'description': 'Add Payment Method',
      'prefill': {
        'contact': '9999999999',
        'email': 'test@example.com',
      },
    };

    try {
      debugPrint("Opening Razorpay...");
      // TODO: connect Razorpay instance here if not already
    } catch (e) {
      debugPrint("Razorpay error: $e");
    }
  }
}
