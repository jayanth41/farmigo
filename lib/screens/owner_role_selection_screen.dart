import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/owner_onboarding_service.dart';
import '../widgets/snackbar_helper.dart';

/// Role Selection Screen
/// Shows when user has completed onboarding but hasn't selected a role.
/// User selects between Farmhouse Owner or Co-Owner
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _loading = false;
  late OwnerOnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _onboardingService = OwnerOnboardingService();
  }

  Future<void> _selectRole(String role) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showAppSnack(context, 'Please sign in to continue', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      // Save role selection
      await _onboardingService.setActiveRole(role);

      if (!mounted) return;

      showAppSnack(
        context,
        'Role selected! Redirecting to dashboard...',
        isError: false,
      );

      // Delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to appropriate dashboard
      String routeName = role == 'farmhouse'
          ? '/farmhouse_dashboard'
          : '/coowner_dashboard';

      Navigator.of(context).pushNamedAndRemoveUntil(
        routeName,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error selecting role: $e');
      showAppSnack(context, 'Error selecting role: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Welcome, Owner!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your onboarding is complete. Select your role to get started.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // Farmhouse Owner option
              _buildRoleCard(
                context,
                icon: Icons.home_work,
                title: 'Farmhouse Owner',
                description: 'Manage farmhouse bookings and properties',
                color: Colors.green,
                onTap: _loading ? null : () => _selectRole('farmhouse'),
              ),
              const SizedBox(height: 24),

              // Co-Owner option
              _buildRoleCard(
                context,
                icon: Icons.people,
                title: 'Co-Owner',
                description: 'Manage co-owned properties',
                color: Colors.blue,
                onTap: _loading ? null : () => _selectRole('cOwner'),
              ),

              const Spacer(),

              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can switch roles later from your dashboard settings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Role',
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: color, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
