import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/owner_onboarding_model.dart';
import '../services/owner_onboarding_service.dart';
import 'owner_onboarding_screen_1.dart';
import 'owner_onboarding_screen_2.dart';
import 'owner_onboarding_screen_3.dart';
import 'owner_role_selection_screen.dart';
import 'farmhouse_owner_dashboard_new.dart';
import 'coowner_dashboard_new.dart';
import 'owner_pending_approval_screen.dart';
import 'owner_rejected_screen.dart';

/// Smart Owner Dashboard Router
/// Handles all onboarding logic and role-based routing
/// 
/// Flow:
/// 1. Check onboarding status
/// 2. If not started → Screen 1
/// 3. If in_progress → Resume from incomplete screen
/// 4. If completed → Check activeRole
///    - If null → Role Selection
///    - If farmhouse → Farmhouse Dashboard
///    - If cOwner → Co-Owner Dashboard
class OwnerDashboardRouter extends StatefulWidget {
  const OwnerDashboardRouter({super.key});

  @override
  State<OwnerDashboardRouter> createState() => _OwnerDashboardRouterState();
}

class _OwnerDashboardRouterState extends State<OwnerDashboardRouter> {
  late OwnerOnboardingService _onboardingService;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _onboardingService = OwnerOnboardingService();
    _checkAndRouteUser();
  }

  Future<void> _checkAndRouteUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        if (!mounted) return;
        debugPrint('[Router] No user logged in');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }

      debugPrint('[Router] Checking onboarding status for user: ${user.uid}');

      // Get or create onboarding data
      final onboardingData = await _onboardingService.getOrCreateOnboardingData();

      if (!mounted) return;

      debugPrint('[Router] Onboarding Status: ${onboardingData.onboardingStatus}');
      debugPrint('[Router] Completed Screens: ${onboardingData.completedScreens}');

      // Route based on onboarding status
      _routeByOnboardingStatus(onboardingData);
    } catch (e) {
      if (!mounted) return;
      debugPrint('[Router] Error: $e');
      setState(() {
        _error = 'Error loading dashboard: $e';
        _loading = false;
      });
    }
  }

  void _routeByOnboardingStatus(OwnerOnboardingModel model) {
    debugPrint('[Router] Routing user with status: ${model.onboardingStatus}');

    // Not started onboarding
    if (model.onboardingStatus == 'not_started') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen1()),
      );
      return;
    }

    // In progress onboarding - resume from last incomplete screen
    if (model.onboardingStatus == 'in_progress') {
      // Check which screens are complete and route to incomplete one
      if (!model.isScreenCompleted('screen_1')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen1()),
        );
        return;
      }
      if (!model.propertyDetailsCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen2()),
        );
        return;
      }
      if (!model.propertiesAdded) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen3()),
        );
        return;
      }
      // If all screens are done, mark as completed
      _markOnboardingComplete(model);
      return;
    }

    // Onboarding completed - check owner status
    if (model.onboardingStatus == 'completed') {
      // Check if pending approval (most important - must be checked first)
      if (model.verificationStatus == 'pending_verification') {
        debugPrint('[Router] Owner pending approval');

        // If the user already has an activeRole chosen, allow access to the
        // corresponding owner dashboard even while verification is pending.
        // This lets owners manage their properties while admin approval for
        // the onboarding is still in progress.
        if (model.activeRole != null && model.activeRole != 'null') {
          debugPrint('[Router] activeRole present during pending verification: ${model.activeRole} — routing to owner dashboard');
          if (model.activeRole == 'farmhouse' || model.activeRole == 'farmhouse_owner') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const FarmhouseOwnerDashboardNew()),
            );
            return;
          }

          if (model.activeRole == 'cOwner' || model.activeRole == 'coowner' || model.activeRole == 'co_owner') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CoOwnerDashboardNew()),
            );
            return;
          }

          // Fallback: if we don't know the exact role, route to farmhouse dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FarmhouseOwnerDashboardNew()),
          );
          return;
        }

        // No active role yet — show the pending approval screen as before
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerPendingApprovalScreen()),
        );
        return;
      }

      // Check if rejected
      if (model.verificationStatus == 'rejected') {
        debugPrint('[Router] Owner rejected');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerRejectedScreen()),
        );
        return;
      }

      // Check if verified - then proceed to role selection or dashboard
      if (model.verificationStatus == 'verified') {
        if (model.activeRole == null || model.activeRole == 'null') {
          // Show role selection
          debugPrint('[Router] Showing role selection');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
          return;
        }

        // Route to appropriate dashboard
        if (model.activeRole == 'farmhouse') {
          debugPrint('[Router] Routing to farmhouse dashboard');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FarmhouseOwnerDashboardNew()),
          );
          return;
        }

        if (model.activeRole == 'cOwner') {
          debugPrint('[Router] Routing to coowner dashboard');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CoOwnerDashboardNew()),
          );
          return;
        }
      }
    }
  }

  Future<void> _markOnboardingComplete(OwnerOnboardingModel model) async {
    try {
      await _onboardingService.updateOnboardingStatus('completed');
      if (!mounted) return;
      _routeByOnboardingStatus(model..onboardingStatus = 'completed');
    } catch (e) {
      debugPrint('[Router] Error marking complete: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading your dashboard...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Unknown error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _checkAndRouteUser();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // This should not be reached as we navigate away, but just in case
    return const Scaffold(
      body: Center(
        child: Text('Initializing...'),
      ),
    );
  }
}
