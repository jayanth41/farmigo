import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/snackbar_helper.dart';
import '../navigation/app_routes.dart';
import 'home_screen.dart';
import '../main.dart';

/// OTP screen for phone-based verification using Firebase Auth.
class OTPScreen extends StatefulWidget {
  final String value;
  final String? verificationId;

  const OTPScreen({super.key, required this.value, this.verificationId});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  final List<TextEditingController> _digitControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocus = List.generate(6, (_) => FocusNode());
  Timer? _resendTimer;
  int _secondsLeft = 0;
  bool _isSending = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Automatically start the send OTP flow for the provided value
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    if (_isSending) return; // prevent duplicate sends
    _isSending = true;
    setState(() {});
    // Only phone OTP flows are supported. If a verificationId was already
    // provided (from the previous screen), treat the OTP as sent and start
    // the cooldown. Otherwise attempt a fallback send using the controller.
    if (widget.verificationId != null && widget.verificationId!.isNotEmpty) {
      showAppSnack(context, 'OTP sent to ${widget.value}', isSuccess: true);
      _startResendCooldown();
      _isSending = false;
      setState(() {});
      return;
    }

    // Fallback: trigger a send using the AuthController when verificationId
    // wasn't passed. This keeps backward compatibility for callers that rely
    // on the controller.
    var ok = false;
    String? caughtError;
    try {
      ok = await auth.sendPhoneOTP(widget.value);
    } catch (e) {
      caughtError = e.toString();
      debugPrint('sendPhoneOTP threw: $e');
    }

    if (!mounted) return;
    if (ok) {
      showAppSnack(context, 'OTP sent to ${widget.value}', isSuccess: true);
      _startResendCooldown();
      _isSending = false;
      setState(() {});
      return;
    }

    final err = caughtError ?? auth.errorMessage ?? '';
    showAppSnack(context, err.isNotEmpty ? err : 'Failed to send phone OTP', isError: true);
    _isSending = false;
    setState(() {});
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _secondsLeft = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) {
          t.cancel();
        }
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    _otpController.dispose();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocus) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }
  Future<void> _verify() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    // Aggregate digits into OTP (if digit boxes used)
    String otp = _otpController.text.trim();
    if (otp.isEmpty) {
      otp = _digitControllers.map((c) => c.text).join();
    }
    if (otp.isEmpty) {
      showAppSnack(context, 'Enter OTP', isError: true);
      return;
    }

    if (_isVerifying) return; // prevent duplicates
    if (otp.length < 6) {
      showAppSnack(context, 'Enter all 6 digits', isError: true);
      return;
    }

    _isVerifying = true;
    setState(() {});

    bool ok = false;
    try {
      // Only phone verification is supported here. If a verificationId was
      // supplied by the caller, use it to build the credential and sign in.
      if (widget.verificationId != null && widget.verificationId!.isNotEmpty) {
        final cred = PhoneAuthProvider.credential(verificationId: widget.verificationId!, smsCode: otp.trim());
        final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
        final user = userCred.user;
        if (user == null) {
          _isVerifying = false;
          setState(() {});
          showAppSnack(context, 'Phone sign-in failed', isError: true);
          ok = false;
        } else {
          // Ensure user doc exists
          try {
            final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
            final snap = await doc.get();
            if (!snap.exists) {
              await doc.set({
                'uid': user.uid,
                'name': user.displayName ?? '',
                'phone': user.phoneNumber ?? '',
                'provider': 'phone',
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          } catch (e) {
            debugPrint('Failed to create user doc after sign-in: $e');
          }
          
          // Save FCM token for push notifications
          await saveFcmTokenToFirestore(user.uid);
          
          ok = true;
        }
      } else {
        // Fallback: use controller if verificationId wasn't provided
        ok = await auth.verifyPhoneOTP(otp);
      }
    } on FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('too-many-requests') || code.contains('quota') || code.contains('rate-limit')) {
        showAppSnack(context, 'Too many requests — please wait before trying again', isError: true);
      } else if (code.contains('app-not-authorized') || code.contains('not-authorized')) {
        showAppSnack(context, 'App not authorized for phone auth. Check Play Integrity & SHA keys', isError: true);
      } else {
        showAppSnack(context, e.message ?? 'Verification failed', isError: true);
      }
      ok = false;
    } catch (e) {
      showAppSnack(context, auth.errorMessage ?? e.toString(), isError: true);
      ok = false;
    }

    if (!mounted) return;
    _isVerifying = false;
    setState(() {});

    if (ok) {
      showAppSnack(context, 'Login successful', isSuccess: true);
      // Remove all previous routes (including Login) so back won't return to them
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      final msg = auth.errorMessage ?? 'Verification failed';
      final lower = msg.toLowerCase();
      if (lower.contains('no verification') || lower.contains('verification in progress') || lower.contains('not in progress')) {
        showAppSnack(context, '$msg — please go back and resend OTP', isError: true);
      } else {
        showAppSnack(context, msg, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text('Welcome Back', style: txt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Enter OTP sent to your phone', style: txt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.7))),
              const SizedBox(height: 20),

              // Row: Change Number / Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Change Number'),
                  ),
                  TextButton(
                    onPressed: (_secondsLeft > 0 || _isSending) ? null : () async {
                      await _start();
                    },
                    child: _secondsLeft > 0 ? Text('Resend in ${_secondsLeft}s') : const Text('Resend OTP'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // OTP boxes (responsive width)
              LayoutBuilder(builder: (context, constraints) {
                final screenW = constraints.maxWidth;
                const horizontalSpacing = 12.0;
                const totalSpacing = horizontalSpacing * 5;
                final available = screenW - totalSpacing;
                double boxW = (available / 6).clamp(40.0, 56.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: boxW,
                      height: 56,
                      child: TextField(
                        controller: _digitControllers[i],
                        focusNode: _digitFocus[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: txt.titleLarge,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty) {
                            if (i + 1 < _digitFocus.length) {
                              _digitFocus[i + 1].requestFocus();
                            } else {
                              _digitFocus[i].unfocus();
                            }
                          } else {
                            if (i - 1 >= 0) _digitFocus[i - 1].requestFocus();
                          }
                          _otpController.text = _digitControllers.map((c) => c.text).join();
                        },
                      ),
                    );
                  }),
                );
              }),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      String otp = _otpController.text.trim();
                      if (otp.isEmpty) otp = _digitControllers.map((c) => c.text).join();
                      if (_isVerifying || otp.length < 6) return;
                      _verify();
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.9)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: _isVerifying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Verify OTP', style: txt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
