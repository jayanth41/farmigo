import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_property_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  Future<Map<String, dynamic>?> _getOwnerBasicDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    return snap.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _getOwnerBasicDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};

            final name = data['name'] ?? 'Owner';
            final phone = data['phone'] ?? 'Not available';
            final email = data['email'] ?? 'Not available';

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  const Icon(
                    Icons.house_outlined,
                    size: 90,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Welcome, $name 👋",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Phone: $phone\nEmail: $email",
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "List your property, manage bookings, and start earning with your space.",
                    style:
                        TextStyle(fontSize: 15, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AddPropertyScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Continue to Add Property",
                        style: TextStyle(
                            fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
