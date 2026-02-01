import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/snackbar_helper.dart';
import '../navigation/app_routes.dart';

enum AuthType { email, phone }

/// Unified OTP screen for email (Supabase) and phone (Firebase).
class OTPScreen extends StatefulWidget {
  final String value;
  final AuthType authType;

  const OTPScreen({super.key, required this.value, required this.authType});

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

    if (widget.authType == AuthType.email) {
      final ok = await auth.sendEmailOTP(widget.value);
      if (!mounted) return;
      if (ok) {
        showAppSnack(context, 'OTP sent to ${widget.value}', isSuccess: true);
        _startResendCooldown();
      } else {
        showAppSnack(context, auth.errorMessage ?? 'Failed to send email OTP', isError: true);
      }
      _isSending = false;
      setState(() {});
    } else {
      // Try sending the phone OTP. If Play Integrity / reCAPTCHA errors occur
      // (common message: "This request is missing a valid app identifier"),
      // attempt a safe testing fallback by disabling app verification for this
      // runtime and retrying once. This keeps existing Firebase logic intact
      // but provides a fallback when native Play Integrity isn't configured.
      var ok = false;
      String? caughtError;
      try {
        ok = await auth.sendPhoneOTP(widget.value);
      } catch (e) {
        // Capture unexpected exceptions from the controller
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
      // Detect common Play Integrity / reCAPTCHA error messages
      final lower = err.toLowerCase();
  if (lower.contains('missing a valid app identifier') || lower.contains('play integrity') || lower.contains('recaptcha') || lower.contains('app identifier')) {
        // Play Integrity / reCAPTCHA appears to be failing. Do not automatically
        // retry. Instead, show a friendly dialog explaining the issue and give
        // an option to enable a developer-only testing fallback (debug builds
        // only). This prevents silent retries in production and follows your
        // instruction to handle failures gracefully.
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Verification blocked'),
            content: const Text(
                'Play Integrity / reCAPTCHA validation failed for this device.\n\nIf you are developing, you can enable a testing fallback to bypass device verification (debug builds only). For production, configure Play Integrity and add your app SHA-256 in the Firebase Console and Play Console.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('How to fix'),
              ),
              if (kDebugMode)
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
                      showAppSnack(context, 'Test fallback enabled — retrying OTP send', isError: false);
                      final retry = await auth.sendPhoneOTP(widget.value);
                      if (!mounted) return;
                      if (retry) {
                        showAppSnack(context, 'OTP sent to ${widget.value}', isSuccess: true);
                        _startResendCooldown();
                      } else {
                        showAppSnack(context, auth.errorMessage ?? 'Retry failed', isError: true);
                      }
                    } catch (e) {
                      debugPrint('Test fallback failed: $e');
                      showAppSnack(context, 'Test fallback failed: $e', isError: true);
                    }
                  },
                  child: const Text('Use test fallback'),
                ),
            ],
          ),
        );
        _isSending = false;
        setState(() {});
        return;
      }

      // final fallback: show the original error
      showAppSnack(context, err.isNotEmpty ? err : 'Failed to send phone OTP', isError: true);
      _isSending = false;
      setState(() {});
    }
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
      if (widget.authType == AuthType.email) {
        ok = await auth.verifyEmailOTP(widget.value, otp);
      } else {
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
      Navigator.pushReplacementNamed(context, AppRoutes.home);
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
    // Use a concise title for the app bar and show the welcome/description in the body
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Back'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text('Welcome Back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Enter OTP sent to your email/phone', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
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
                // padding accounted above; calculate a reasonable box width
                final horizontalSpacing = 12.0; // margin between boxes
                final totalSpacing = horizontalSpacing * 5; // between 6 boxes
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
                        style: Theme.of(context).textTheme.titleLarge,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty) {
                            // move focus
                            if (i + 1 < _digitFocus.length) {
                              _digitFocus[i + 1].requestFocus();
                            } else {
                              _digitFocus[i].unfocus();
                            }
                          } else {
                            if (i - 1 >= 0) _digitFocus[i - 1].requestFocus();
                          }
                          // update aggregated controller
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
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    // compute current otp length
                    String otp = _otpController.text.trim();
                    if (otp.isEmpty) otp = _digitControllers.map((c) => c.text).join();
                    if (_isVerifying || otp.length < 6) return;
                    _verify();
                  },
                  child: _isVerifying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify OTP'),
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
