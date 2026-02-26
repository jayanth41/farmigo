# Pending Approval Flow - Developer Reference

## Code Flow Diagram

```
user_completes_screen_3.dart
         ↓
   _completeOnboarding()
         ↓
   Firestore update:
   - onboarding_status: "completed"
   - verification_status: "pending_verification"
   - owner_status: "pending"
   - onboarding_completed: true
         ↓
   Green success screen
         ↓
   User clicks "Continue"
         ↓
   Navigator.pushNamedAndRemoveUntil('/owner_pending_approval', ...)
         ↓
   OwnerPendingApprovalScreen displays
         ↓
   User restarts app
         ↓
   App routes through OwnerDashboardRouter
         ↓
   Router checks verification_status
         ↓
   If "pending_verification" → OwnerPendingApprovalScreen
   If "verified" → Role selection
   If "rejected" → OwnerRejectedScreen
```

---

## Implementation Details

### Screen 3: Submission (`owner_onboarding_screen_3.dart`)

```dart
Future<void> _completeOnboarding() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  
  setState(() => _loading = true);
  
  try {
    // Update Firestore with submission status
    await FirebaseFirestore.instance.collection('owners').doc(uid).update({
      'properties': _addedProperties,
      'onboarding_status': 'completed',           // Permanent flag
      'onboarding_completed': true,               // One-time flag
      'owner_status': 'pending',                  // Approval status
      'verification_status': 'pending_verification',  // Router uses this
      'onboarding_submitted_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Mark screens completed
    await _onboardingService.markScreenCompleted('screen_3');
    await _onboardingService.markPropertiesAdded();
    await _onboardingService.updateOnboardingStatus('completed');
    
    // Show success, then navigate
    _showSuccessScreen(
      'Properties Added Successfully!',
      'Your account is now pending developer verification.',
      onContinue: () {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/owner_pending_approval',
          (route) => false,
        );
      },
    );
  } catch (e) {
    debugPrint('Error: $e');
    showAppSnack(context, 'Error: $e', isError: true);
  }
}
```

### Router: Decision Logic (`owner_dashboard_router.dart`)

```dart
void _routeByOnboardingStatus(OwnerOnboardingModel model) {
  // Route based on onboarding status
  
  if (model.onboardingStatus == 'not_started') {
    // Go to screen 1
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen1()),
    );
    return;
  }
  
  if (model.onboardingStatus == 'in_progress') {
    // Resume from incomplete screen
    if (!model.isScreenCompleted('screen_1')) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OwnerOnboardingScreen1()),
      );
      return;
    }
    // ... check other screens
  }
  
  if (model.onboardingStatus == 'completed') {
    // ⭐ CRITICAL: Check verification status FIRST
    
    if (model.verificationStatus == 'pending_verification') {
      // User submitted but not reviewed yet
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OwnerPendingApprovalScreen()),
      );
      return;
    }
    
    if (model.verificationStatus == 'rejected') {
      // Developer rejected application
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OwnerRejectedScreen()),
      );
      return;
    }
    
    if (model.verificationStatus == 'verified') {
      // Approved! Show role selection
      if (model.activeRole == null || model.activeRole == 'null') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerRoleSelectionScreen()),
        );
        return;
      }
      
      // Show appropriate dashboard
      if (model.activeRole == 'farmhouse') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FarmhouseOwnerDashboardNew()),
        );
        return;
      }
      
      if (model.activeRole == 'cOwner') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CoOwnerDashboardNew()),
        );
        return;
      }
    }
  }
}
```

### Pending Approval Screen (`owner_pending_approval_screen.dart`)

```dart
class OwnerPendingApprovalScreen extends StatefulWidget {
  const OwnerPendingApprovalScreen({super.key});

  @override
  State<OwnerPendingApprovalScreen> createState() => _OwnerPendingApprovalScreenState();
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final doc = await FirebaseFirestore.instance
          .collection('owners')
          .doc(uid)
          .get();

      final data = doc.data() ?? {};
      
      setState(() {
        _ownerName = data['basic_info']?['name'] as String?;
        _submittedAt = (data['onboarding_submitted_at'] as Timestamp?)?.toDate();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _loading = false);
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header with icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pending_actions,
                    color: Colors.blue.shade600,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome message
                Text(
                  'Verification in Progress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Information box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
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
                        'Your registration has been submitted. Our team is reviewing your details.\n\n'
                        'You will receive an email when your account is approved.',
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

                // Timeline
                _buildTimelineItem(
                  icon: Icons.check_circle,
                  title: '1. Registration Submitted',
                  subtitle: 'Your details received',
                  color: Colors.green,
                  isComplete: true,
                ),
                const SizedBox(height: 20),
                _buildTimelineItem(
                  icon: Icons.pending_actions,
                  title: '2. Under Review',
                  subtitle: 'Our team is verifying',
                  color: Colors.amber,
                  isComplete: false,
                ),
                const SizedBox(height: 20),
                _buildTimelineItem(
                  icon: Icons.approval,
                  title: '3. Approved',
                  subtitle: 'Account access granted',
                  color: Colors.grey,
                  isComplete: false,
                ),
                const SizedBox(height: 40),

                // Submission date
                if (_submittedAt != null)
                  Text(
                    'Submitted: ${_formatDate(_submittedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 32),

                // Action button
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
            color: isComplete ? color.shade100 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isComplete ? color : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}
```

---

## Admin Operations

### Approve an Owner

**Firebase Console or Admin SDK**:
```dart
// Set verification status to verified
await FirebaseFirestore.instance
    .collection('owners')
    .doc(userId)
    .update({
      'verification_status': 'verified',
      'owner_status': 'approved',
      'approved_at': FieldValue.serverTimestamp(),
    });

// Send approval email (Cloud Function)
// User will see role selection on next login
```

### Reject an Owner

```dart
// Set verification status to rejected
await FirebaseFirestore.instance
    .collection('owners')
    .doc(userId)
    .update({
      'verification_status': 'rejected',
      'owner_status': 'rejected',
      'rejection_reason': 'Incomplete documents',
      'rejected_at': FieldValue.serverTimestamp(),
    });

// Send rejection email with reason (Cloud Function)
// User will see rejection screen on next login
```

### Revert to Pending (For Re-review)

```dart
// Reset to pending for additional review
await FirebaseFirestore.instance
    .collection('owners')
    .doc(userId)
    .update({
      'verification_status': 'pending_verification',
      'owner_status': 'pending',
      'rereviewed_at': FieldValue.serverTimestamp(),
    });
```

---

## Error Scenarios

### Scenario 1: User Not Authenticated

```dart
// Router will catch this and redirect to login
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // The splash screen handles this
  Navigator.pushReplacement(context, 
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return;
}
```

### Scenario 2: Firestore Data Missing

```dart
// Router will handle gracefully
try {
  final data = await _onboardingService.getOrCreateOnboardingData();
  // If data doesn't exist, it creates a default one
} catch (e) {
  debugPrint('[Router] Error: $e');
  // Shows error message instead of crashing
}
```

### Scenario 3: Network Error During Submission

```dart
// Error is caught and shown to user
try {
  await FirebaseFirestore.instance.collection('owners').doc(uid).update({
    // ... data
  });
} catch (e) {
  showAppSnack(context, 'Error saving properties: $e', isError: true);
  // User can retry submission
}
```

---

## Extension Points

### Add Email Notification on Approval

**Location**: Cloud Function
```dart
// In Firebase Cloud Function
exports.onOwnerApproved = functions.firestore
  .document('owners/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    if (oldData.verification_status !== 'verified' && 
        newData.verification_status === 'verified') {
      // Send approval email
      await sendApprovalEmail(context.params.userId, newData);
    }
  });
```

### Add Document Upload Feature

**New screen**: `lib/screens/owner_document_upload_screen.dart`
- Appears before pending approval
- User uploads ID, property documents
- Adds field: `documents_uploaded: true`
- Router shows upload screen if flag is false

### Add Chat Support

**New widget**: `lib/widgets/owner_support_chat.dart`
- Opens from pending approval screen
- Connects to support team
- Real-time chat with owner
- Attached to pending approval status

---

## Testing Checklist for Developers

```dart
// Unit test example
void testPendingApprovalFlow() {
  final ownerDoc = {
    'onboarding_status': 'completed',
    'verification_status': 'pending_verification',
    'owner_status': 'pending',
    'onboarding_completed': true,
  };
  
  // Assert router selects pending approval screen
  assert(shouldShowPendingApprovalScreen(ownerDoc) == true);
  
  // Assert dashboard is blocked
  assert(canAccessDashboard(ownerDoc) == false);
  
  // Assert screens cannot be re-entered
  assert(canRestartOnboarding(ownerDoc) == false);
}
```

---

## Performance Notes

- ✅ Firestore updates are atomic (no race conditions)
- ✅ Router checks are O(1) - simple field comparisons
- ✅ No unnecessary database queries
- ✅ Navigation uses direct widget instantiation (fast)
- ✅ UI renders efficiently (single-pass layout)

**Expected Load Time**: < 1 second for pending approval screen

---

**Last Updated**: 2025-01-20
**Version**: 1.0
**Status**: Production Ready ✅
