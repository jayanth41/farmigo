import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text.trim();
    final fresh = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || fresh.isEmpty || confirm.isEmpty) {
      _showMessage('All fields are required');
      return;
    }
    if (fresh.length < 6) {
      _showMessage('New password must be at least 6 characters');
      return;
    }
    if (fresh != confirm) {
      _showMessage('New passwords do not match');
      return;
    }

    final user = supabase.auth.currentUser;
    final email = user?.email;
    if (email == null) {
      _showMessage('No authenticated user found');
      return;
    }

    setState(() => _loading = true);

    try {
      // Re-authenticate using email + current password
      final res = await supabase.auth.signInWithPassword(email: email, password: current);
      if (res.user == null) {
        // Sign-in failed
        _showMessage('Wrong current password');
        setState(() => _loading = false);
        return;
      }

      // Update password
      await supabase.auth.updateUser(UserAttributes(password: fresh));
      // If no exception thrown above, consider it successful
      _showMessage('Password changed successfully');
      setState(() => _loading = false);
      Navigator.pop(context);
      return;
    } on AuthException catch (e) {
      _showMessage(e.message);
      setState(() => _loading = false);
    } catch (e) {
      _showMessage('An error occurred. Please try again');
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _currentController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Current Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurface),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurface),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurface),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: _loading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                    : Text('Change Password', style: textTheme.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
