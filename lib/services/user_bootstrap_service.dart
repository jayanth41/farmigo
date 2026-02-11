import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserBootstrapService {
  static Future<void> ensureUserDoc() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final snap = await docRef.get();

    final Map<String, dynamic> baseData = {
      "uid": uid,
      "name": user.displayName ?? "",
      "email": user.email ?? "",
      "phone": user.phoneNumber ?? "",
      "photoUrl": user.photoURL ?? "",
      "lastUpdated": FieldValue.serverTimestamp(),
    };

    // Get FCM token
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    if (!snap.exists) {
      // FIRST TIME LOGIN → create full document
      await docRef.set({
        ...baseData,
        "createdAt": FieldValue.serverTimestamp(),
        "role": "user",
        "roles": [],
        "activeRole": null,
        "isOwner": false,
        "fcmToken": fcmToken,
      });
    } else {
      // EXISTING USER → only update missing fields
      await docRef.set({
        ...baseData,
        if (fcmToken != null) "fcmToken": fcmToken,
      }, SetOptions(merge: true));
    }
  }
}