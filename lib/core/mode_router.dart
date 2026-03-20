import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/main_scaffold.dart';
import '../screens/owner/owner_main_scaffold.dart';

class ModeRouter extends StatelessWidget {
  const ModeRouter({super.key});

  Future<String> _getRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return "user";

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    final data = doc.data();

    return (data?['activeRole'] ?? 'user').toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getRole(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = (snap.data ?? 'user').toString();

        // Normalize owner roles
        final isOwner = role == 'owner' || role == 'farmhouse_owner' || role == 'car_owner';

        if (isOwner) {
          return const OwnerMainScaffold();
        }

        return MainScaffold(
          tabs: Map.fromEntries(
            BottomTab.values.map(
              (t) => MapEntry(t, const SizedBox.shrink()),
            ),
          ),
        );
      },
    );
  }
}