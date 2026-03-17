import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final bookingsStream = FirebaseFirestore.instance
        .collection("bookings")
        .where("ownerId", isEqualTo: currentUser.uid)
        .orderBy("createdAt", descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Bookings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final propertyName = data['propertyName'] ?? 'Property';
              final guestName = data['userName'] ?? 'Guest';
              final status = data['status'] ?? 'pending';
              final date = data['visitDate'] ?? 'N/A';
              final bookingId = data['bookingId'] ?? 'N/A';
              final paymentStatus = data['paymentStatus'] ?? 'unknown';
              final bookingType = data['bookingType'] ?? 'overnight';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(
                    propertyName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Booking ID: $bookingId"),
                      Text("Guest: $guestName"),
                      Text("Date: $date"),
                      Text("Type: $bookingType"),
                      Text("Payment: $paymentStatus"),
                      Text("Status: $status"),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
