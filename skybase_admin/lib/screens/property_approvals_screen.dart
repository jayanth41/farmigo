import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyApprovalsScreen extends StatelessWidget {
  const PropertyApprovalsScreen({super.key});

  Future<void> approveProperty(
      String propertyId, String ownerId, String propertyName) async {

    await FirebaseFirestore.instance
        .collection("properties")
        .doc(propertyId)
        .update({
      "status": "approved",
    });

    // Send notification
    await FirebaseFirestore.instance.collection("notifications").add({
      "title": "Property Approved",
      "message": "Your property \"$propertyName\" has been approved.",
      "userId": ownerId,
      "type": "property_status",
      "status": "approved",
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectProperty(
      String propertyId, String ownerId, String propertyName) async {

    await FirebaseFirestore.instance
        .collection("properties")
        .doc(propertyId)
        .update({
      "status": "rejected",
    });

    await FirebaseFirestore.instance.collection("notifications").add({
      "title": "Property Rejected",
      "message": "Your property \"$propertyName\" was rejected.",
      "userId": ownerId,
      "type": "property_status",
      "status": "rejected",
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Property Approvals"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("properties")
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = snapshot.data!.docs;

          if (properties.isEmpty) {
            return const Center(child: Text("No pending properties"));
          }

          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {

              final data =
                  properties[index].data() as Map<String, dynamic>;

              final propertyId = properties[index].id;
              final propertyName = data["propertyName"] ?? "Property";
              final ownerId = data["ownerId"];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(propertyName),
                  subtitle: Text(data["city"] ?? ""),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        onPressed: () {
                          approveProperty(
                              propertyId, ownerId, propertyName);
                        },
                        child: const Text("Approve"),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () {
                          rejectProperty(
                              propertyId, ownerId, propertyName);
                        },
                        child: const Text("Reject"),
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
}