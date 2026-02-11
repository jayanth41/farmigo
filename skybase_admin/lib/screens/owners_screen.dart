import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnersScreen extends StatelessWidget {
  const OwnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Owners Approval",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('[OwnersScreen] Firestore stream error: ${snapshot.error}');
                  final err = snapshot.error.toString();
                  if (err.contains('permission-denied')) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Permission denied when reading users from Firestore.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'This admin app does not have permission to read user documents.\n'
                              'Possible fixes:\n'
                              '- Update Firestore security rules to allow reads for admin users (use custom claim `admin: true`), or\n'
                              '- Sign in with an account that has elevated privileges, or\n'
                              '- Use the Firestore emulator for local testing.',
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  }

                  return Center(child: Text('Error loading users: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  debugPrint('[OwnersScreen] No users in snapshot (connectionState=${snapshot.connectionState})');
                  return const Center(child: Text("No users found in Firestore"));
                }

                // Debug: print all users and their structure (also visible in console)
                debugPrint('=== ALL USERS IN FIRESTORE ===');
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  debugPrint('User ID: ${doc.id}');
                  debugPrint('Data: $data');
                  debugPrint('---');
                }

                // Filter for users who have any owner role (farmhouse_owner, car_owner, etc)
                final owners = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final roles = (data["roles"] as List?)?.cast<String>() ?? [];
                  final role = data["role"] as String?;

                  debugPrint('Checking user ${doc.id}: roles=$roles, role=$role');

                  // Check if user has any owner role
                  return roles.isNotEmpty || (role != null && role != "user");
                }).toList();

                debugPrint('Filtered owners count: ${owners.length}');

                if (owners.isEmpty) {
                  return Center(child: Text("No owners found (total users: ${snapshot.data!.docs.length})"));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("User ID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Phone")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Roles")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: owners.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final name = data["displayName"]?.toString() ?? data["fullName"]?.toString() ?? "—";
                      final phone = data["phone"]?.toString() ?? "—";
                      final email = data["email"]?.toString() ?? "—";
                      final roles = (data["roles"] as List?)?.join(", ") ?? data["role"]?.toString() ?? "user";

                      return DataRow(cells: [
                        DataCell(Text(doc.id)),
                        DataCell(Text(name)),
                        DataCell(Text(phone)),
                        DataCell(Text(email)),
                        DataCell(Text(roles)),
                        DataCell(Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(doc.id)
                                    .update({"approvalStatus": "approved"});
                              },
                              child: const Text("Approve"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(doc.id)
                                    .update({"approvalStatus": "rejected"});
                              },
                              child: const Text("Reject"),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}