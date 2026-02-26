# Email Verification System - Setup Guide

## 📧 PHASE 4: Email Verification System (Ready for Implementation)

This guide outlines how to implement the email verification system using Firebase Cloud Functions.

---

## 🎯 REQUIREMENTS

```
Step 1: Owner completes all 3 onboarding screens
        └─> onboarding_status = "completed"
        └─> verification_status = "pending_verification"

Step 2: Owner data pending developer review
        └─> Developer logs into admin panel
        └─> Reviews owner details
        └─> Clicks "Approve"

Step 3: System triggers email send
        └─> Update: email_verification_sent = true
        └─> Update: verification_status = "verified"
        └─> Email sent to owner with welcome message

Step 4: Owner receives email
        └─> Email contains: Welcome, Account verified, Dashboard link
        └─> Owner can now access full dashboard

Step 5: (Optional) Owner clicks email link
        └─> Update: email_verified = true
```

---

## 🛠️ FIREBASE CLOUD FUNCTIONS SETUP

### Function 1: Trigger Email on Verification

**File: `functions/sendOwnerVerificationEmail.js`** (to be created)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Setup your email transporter (Gmail, SendGrid, etc.)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASS,
  }
});

// Trigger when owner verification_status changes to "verified"
exports.sendOwnerVerificationEmail = functions
  .firestore.document('owners/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const newData = change.after.data();
    const oldData = change.before.data();

    // Only send if verification_status changed to "verified"
    if (oldData.verification_status !== 'verified' && 
        newData.verification_status === 'verified' &&
        !oldData.email_verification_sent) {
      
      try {
        const mailOptions = {
          from: 'noreply@farmigo.com',
          to: newData.email,
          subject: `Your Farmigo Account Has Been Verified - Welcome, ${newData.name}!`,
          html: generateEmailTemplate(newData)
        };

        await transporter.sendMail(mailOptions);
        
        // Mark email as sent
        await admin.firestore()
          .collection('owners')
          .doc(userId)
          .update({
            email_verification_sent: true,
            email_sent_at: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log(`Email sent to ${newData.email}`);
        return { success: true };
      } catch (error) {
        console.error('Error sending email:', error);
        
        // Log error for retry
        await admin.firestore()
          .collection('owners')
          .doc(userId)
          .collection('email_failures')
          .add({
            error: error.message,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        
        throw error;
      }
    }
  });

function generateEmailTemplate(ownerData) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .section { margin: 20px 0; padding: 15px; background: white; border-radius: 5px; }
        .cta-button { background: #4CAF50; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 10px; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>✓ Account Verification Complete</h1>
          <p>Welcome to Farmigo, ${ownerData.name}!</p>
        </div>
        
        <div class="content">
          <div class="section">
            <h2>Your Account is Ready! 🎉</h2>
            <p>Dear ${ownerData.name},</p>
            <p>Great news! Your Farmigo account has been successfully verified and approved by our team.</p>
          </div>

          <div class="section">
            <h3>Account Status</h3>
            <p>✓ Email verified: ${ownerData.email}</p>
            <p>✓ Property type: ${ownerData.property_type}</p>
            <p>✓ Location: ${ownerData.city}</p>
            <p>✓ Account Status: <strong>ACTIVE</strong></p>
          </div>

          <div class="section">
            <h3>Access Your Dashboard</h3>
            <p>You can now log in to your dashboard and start managing your properties:</p>
            <a href="https://farmigo.com/dashboard" class="cta-button">Go to Dashboard</a>
          </div>

          <div class="section">
            <h3>What You Can Do Now</h3>
            <ul>
              <li>✓ View and manage your properties</li>
              <li>✓ Accept and manage bookings</li>
              <li>✓ View analytics and reports</li>
              <li>✓ Update account settings</li>
              <li>✓ Manage payments and earnings</li>
            </ul>
          </div>

          <div class="section">
            <h3>Quick Tips</h3>
            <ul>
              <li>Add high-quality photos to your property</li>
              <li>Set competitive pricing based on local market</li>
              <li>Enable all notifications for new bookings</li>
              <li>Complete your profile to boost visibility</li>
            </ul>
          </div>

          <div class="section">
            <h3>Need Help?</h3>
            <p>If you have any questions, our support team is here to help:</p>
            <p>
              <strong>Email:</strong> support@farmigo.com<br>
              <strong>Phone:</strong> 1-800-FARMIGO (1-800-327-6446)<br>
              <strong>Hours:</strong> Mon-Fri, 9AM-6PM IST
            </p>
          </div>
        </div>

        <div class="footer">
          <p>© 2026 Farmigo. All rights reserved.</p>
          <p>
            <a href="https://farmigo.com/privacy">Privacy Policy</a> | 
            <a href="https://farmigo.com/terms">Terms of Service</a>
          </p>
        </div>
      </div>
    </body>
    </html>
  `;
}
```

---

## 🔐 ADMIN VERIFICATION SCREEN

Create an admin panel where developers can verify owner accounts.

**Pseudo-code for Admin Screen:**

```dart
class AdminVerificationScreen extends StatefulWidget {
  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  Stream<QuerySnapshot> _pendingOwnersStream;

  @override
  void initState() {
    super.initState();
    _pendingOwnersStream = FirebaseFirestore.instance
        .collection('owners')
        .where('verification_status', isEqualTo: 'pending_verification')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _approveOwner(String userId) async {
    await FirebaseFirestore.instance
        .collection('owners')
        .doc(userId)
        .update({
          'verification_status': 'verified',
          'verified_at': FieldValue.serverTimestamp(),
          'verified_by': FirebaseAuth.instance.currentUser?.uid,
        });
    // Cloud Function triggers automatically → sends email
  }

  Future<void> _rejectOwner(String userId, String reason) async {
    await FirebaseFirestore.instance
        .collection('owners')
        .doc(userId)
        .update({
          'verification_status': 'rejected',
          'rejection_reason': reason,
          'rejected_at': FieldValue.serverTimestamp(),
          'rejected_by': FirebaseAuth.instance.currentUser?.uid,
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Owner Verification')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _pendingOwnersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          
          final owners = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: owners.length,
            itemBuilder: (context, index) {
              final owner = owners[index].data() as Map<String, dynamic>;
              final userId = owners[index].id;
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        owner['name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text('Email: ${owner['email']}'),
                      Text('City: ${owner['city']}'),
                      Text('Property Type: ${owner['property_type']}'),
                      Text('Farm Name: ${owner['farm_name']}'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _approveOwner(userId),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showRejectDialog(userId),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRejectDialog(String userId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Owner'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Rejection reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _rejectOwner(userId, reasonController.text);
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📲 EMAIL VERIFICATION LINK (Optional)

If you want users to confirm email by clicking a link:

**Update Firestore Document:**

```javascript
// In sendOwnerVerificationEmail function, add verification link
const verificationLink = `https://farmigo.com/verify-email?token=${generateVerificationToken(userId)}`;

// Include link in email template
```

**Firebase Function to Handle Click:**

```javascript
exports.verifyEmailLink = functions.https.onRequest(async (req, res) => {
  const { token } = req.query;
  
  const decoded = admin.auth().verifyIdToken(token);
  const userId = decoded.uid;
  
  await admin.firestore()
    .collection('owners')
    .doc(userId)
    .update({
      email_verified: true,
      email_verified_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  
  res.send('Email verified! You can now use all features.');
});
```

---

## 🔄 EMAIL RETRY MECHANISM

**Function for Retrying Failed Emails:**

```javascript
exports.retryFailedEmails = functions
  .pubsub.schedule('every 1 hour')
  .onRun(async (context) => {
    const failedOwnersSnapshot = await admin.firestore()
      .collection('owners')
      .where('verification_status', '==', 'verified')
      .where('email_verification_sent', '==', false)
      .limit(10)
      .get();

    for (const doc of failedOwnersSnapshot.docs) {
      try {
        await sendOwnerVerificationEmail(doc.id, doc.data());
      } catch (error) {
        console.error(`Failed to send email to ${doc.id}:`, error);
      }
    }
  });
```

---

## 📋 IMPLEMENTATION CHECKLIST

- [ ] Set up Firebase Cloud Functions project
- [ ] Install nodemailer and dependencies
- [ ] Configure email provider (Gmail, SendGrid, etc.)
- [ ] Create sendOwnerVerificationEmail function
- [ ] Test email sending with test account
- [ ] Create admin verification screen
- [ ] Deploy Cloud Functions to Firebase
- [ ] Test approval flow end-to-end
- [ ] Test rejection flow
- [ ] Set up email retry mechanism
- [ ] Create error logging system
- [ ] Set up monitoring and alerts

---

## 🔑 ENVIRONMENT VARIABLES

Create `.env` file for Firebase Functions:

```
GMAIL_USER=your-email@gmail.com
GMAIL_PASS=your-app-password
SENDGRID_API_KEY=your-sendgrid-api-key
FIREBASE_PROJECT_ID=your-project-id
```

---

## 📧 EMAIL TEMPLATE PREVIEW

**Subject:** Your Farmigo Account Has Been Verified - Welcome, John!

**Body:**
```
✓ Account Verification Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dear John,

Great news! Your Farmigo account has been successfully verified 
and approved by our team.

Account Status:
✓ Email verified: john@email.com
✓ Property type: Farmhouse
✓ Location: Hyderabad
✓ Account Status: ACTIVE

[Go to Dashboard Button]

What You Can Do Now:
• View and manage your properties
• Accept and manage bookings
• View analytics and reports
• Update account settings

Need Help?
Email: support@farmigo.com
Phone: 1-800-FARMIGO
Hours: Mon-Fri, 9AM-6PM IST

© 2026 Farmigo
```

---

## 🚀 DEPLOYMENT STEPS

1. Create `functions` folder in Firebase project root
2. Run `firebase init functions`
3. Copy function code to `functions/index.js`
4. Set environment variables: `firebase functions:config:set gmail.user="..."  gmail.pass="..."`
5. Deploy: `firebase deploy --only functions`
6. Test in Firebase Console
7. Monitor logs: `firebase functions:log`

---

**Status: Ready for Implementation**

All infrastructure in place. Just needs Cloud Functions setup!
