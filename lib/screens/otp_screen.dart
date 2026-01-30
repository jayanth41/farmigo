import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  Timer? _resendTimer;
  int _resendSeconds = 30;
  bool _canResend = false;

  String get _enteredOtp =>
      _otpControllers.map((c) => c.text).join();

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _enteredOtp;

    if (otp.length != 6) {
      _showSnackBar("Enter 6 digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    final authCtrl = context.read<AuthController>();

    final success = await authCtrl.verifyOTPAndSignIn(
      otpCode: otp,
      phoneNumber: widget.phoneNumber,
    );

    if (!mounted) return;

    if (success) {
      Get.offAllNamed('/home');
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(authCtrl.errorMessage ?? "Invalid OTP");
    }
  }

  void _startResendTimer() {
    // Cancel any existing timer first
    _resendTimer?.cancel();
    setState(() {
      _resendSeconds = 30;
      _canResend = false;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() => _isLoading = true);
    final authCtrl = context.read<AuthController>();
    final success = await authCtrl.startPhoneNumberVerification(widget.phoneNumber);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      _showSnackBar('OTP resent');
      _startResendTimer();
    } else {
      _showSnackBar(authCtrl.errorMessage ?? 'Failed to resend OTP');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // start a non-blocking periodic timer for resend countdown
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Enter OTP sent to ${widget.phoneNumber}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (i) => SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
                    autofocus: i == 0,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (v) => _onOtpChanged(v, i),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Resend timer / action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _canResend
                    ? TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: const Text('Resend OTP'),
                      )
                    : Text('Resend in ${_resendSeconds}s'),
                SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Verify OTP"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
