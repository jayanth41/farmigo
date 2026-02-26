import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Owner Pending Approval Screen
/// Shown after owner submits onboarding but before developer approval
/// This screen blocks dashboard access until verification is complete
class OwnerPendingApprovalScreen extends StatefulWidget {
  const OwnerPendingApprovalScreen({super.key});

  @override
  State<OwnerPendingApprovalScreen> createState() =>
      _OwnerPendingApprovalScreenState();
}

class _OwnerPendingApprovalScreenState extends State<OwnerPendingApprovalScreen> {
  String? _ownerName;
  DateTime? _submittedAt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('owners')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _ownerName = doc['name'] ?? 'Owner';
            _submittedAt = (doc['onboarding_submitted_at'] as Timestamp?)?.toDate();
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
      debugPrint('Error loading owner data: $e');
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Pending icon with animation
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top,
                    color: Colors.amber.shade700,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'Verification in Progress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Main message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dear ${_ownerName ?? "Owner"},',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Thank you for completing your owner registration! 🎉\n\n'
                        'Your registration has been submitted successfully. Our team is currently reviewing your details and documents.\n\n'
                        'You will receive an email notification as soon as your account has been verified and approved.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Timeline section
                _buildTimelineItem(
                  icon: Icons.check_circle,
                  title: '1. Registration Submitted',
                  subtitle: 'Your details have been received',
                  color: Colors.green,
                  isComplete: true,
                ),
                const SizedBox(height: 20),
                _buildTimelineItem(
                  icon: Icons.pending_actions,
                  title: '2. Under Review',
                  subtitle: 'Our team is verifying your documents',
                  color: Colors.amber,
                  isComplete: false,
                ),
                const SizedBox(height: 20),
                _buildTimelineItem(
                  icon: Icons.verified_user,
                  title: '3. Approval Confirmation',
                  subtitle: 'You will receive email when approved',
                  color: Colors.blue,
                  isComplete: false,
                ),
                const SizedBox(height: 40),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What\'s Next?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check your email for verification updates. We typically respond within 24-48 hours.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Submitted date
                if (_submittedAt != null)
                  Text(
                    'Submitted on: ${_formatDate(_submittedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 32),

                // Go to Home button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _goHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Go to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Support link
                Text.rich(
                  TextSpan(
                    text: 'Need help? ',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Contact Support',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isComplete,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isComplete ? color : Colors.grey,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isComplete ? Colors.black : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
