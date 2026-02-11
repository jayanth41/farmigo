import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Users Management",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                final users = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Doc ID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Phone")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Role")),
                    ],
                    rows: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return DataRow(cells: [
                        DataCell(Text(doc.id)),
                        DataCell(Text(data["name"]?.toString() ?? "—")),
                        DataCell(Text(data["phone"]?.toString() ?? "—")),
                        DataCell(Text(data["email"]?.toString() ?? "—")),
                        DataCell(Text(data["role"]?.toString() ?? "—")),
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