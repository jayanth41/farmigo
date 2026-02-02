import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RewardService {
  /// Adds [points] reward points to the currently signed-in user.
  ///
  /// Returns true on success, false on failure. This performs the update in a
  /// transaction: if the user's document exists, it will update or create the
  /// `rewardPoints` field. If the document does not exist the transaction will
  /// attempt to merge the field (this may fail under strict rules where clients
  /// cannot create user documents).
  static Future<bool> addRewardPointsForBooking({int points = 50}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final uid = user.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        if (snapshot.exists) {
          final data = snapshot.data();
          final rp = data?['rewardPoints'];
          if (rp is num) {
            final newPoints = rp.toInt() + points;
            tx.update(docRef, {'rewardPoints': newPoints});
          } else {
            // If the field doesn't exist or isn't numeric, overwrite it with points
            tx.update(docRef, {'rewardPoints': points});
          }
        } else {
          // Document doesn't exist: attempt to merge the rewardPoints field.
          // Note: with strict rules that forbid client-side creation this may fail.
          tx.set(docRef, {'rewardPoints': points}, SetOptions(merge: true));
        }
      });

      debugPrint('Reward points updated: +$points for UID: $uid');
      return true;
    } catch (e) {
      debugPrint('Failed to update reward points: $e');
      return false;
    }
  }
}
