import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../services/supabase_config.dart';

class MfaSetupScreen extends StatefulWidget {
  final Map<String, dynamic> enrollResponse;

  const MfaSetupScreen({super.key, required this.enrollResponse});

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  final _otpController = TextEditingController();
  bool _verifying = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final token = _otpController.text.trim();
    if (token.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a 6-digit code')));
      return;
    }

    final ticket = widget.enrollResponse['ticket'] ?? widget.enrollResponse['ticket_id'] ?? widget.enrollResponse['ticketId'];
    if (ticket == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing enroll ticket')));
      return;
    }

    setState(() => _verifying = true);
    try {
      final url = '$SUPABASE_URL/auth/v1/mfa/verify';
      final accessToken = supabase.auth.currentSession?.accessToken;
      final res = await http.post(Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'ticket': ticket, 'token': token}));

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _verifying = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Two-factor authentication enabled')));
        Navigator.of(context).pop(true);
      } else {
        final msg = res.body.isNotEmpty ? res.body : 'Verification failed';
        setState(() => _verifying = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $msg')));
      }
    } catch (e) {
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpauth = widget.enrollResponse['otpauth_url'] ?? widget.enrollResponse['otpAuthUrl'] ?? widget.enrollResponse['otpauth'];
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Two-Factor Auth', style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Scan the QR code below with Google Authenticator or Authy', style: textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (otpauth != null)
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                                // QR rendering removed to avoid package compatibility issues.
                                // Show the otpauth URL and a copy button so users can generate/scan a QR code externally.
                                SelectableText(otpauth, style: textTheme.bodySmall),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: otpauth));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied OTP auth URL')));
                                  },
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy OTP URL'),
                                ),
                    ],
                  ),
                ),
              )
            else
              Text('QR data not available', style: textTheme.bodyMedium),

            const SizedBox(height: 16),
            Text('After scanning, enter the 6-digit code from your authenticator app', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(counterText: ''),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                child: _verifying ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)) : Text('Verify', style: textTheme.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
