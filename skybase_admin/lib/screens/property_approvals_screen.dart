import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyApprovalsScreen extends StatelessWidget {
  const PropertyApprovalsScreen({super.key});

  Future<void> approveProperty(
      String propertyId, String ownerId, String propertyName) async {
    // Approve a new property (mark as approved/active)
    await FirebaseFirestore.instance.collection("properties").doc(propertyId).update({
      "status": "approved",
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send notification to owner
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
    // Reject a new property submission
    await FirebaseFirestore.instance.collection("properties").doc(propertyId).update({
      "status": "rejected",
      'updatedAt': FieldValue.serverTimestamp(),
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
        // Listen to all property documents and filter client-side for
        // either new submissions (status == 'pending') or edit requests
        // (editApprovalStatus == 'pending'). This keeps the admin able to
        // approve both kinds of workflows.
        stream: FirebaseFirestore.instance.collection("properties").snapshots(),
        builder: (context, snapshot) {

          // Surface Firestore errors instead of leaving the UI stuck on a spinner
          if (snapshot.hasError) {
            return Center(child: Text('Error loading properties: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data available"));
          }

          final allDocs = snapshot.data!.docs;

          final pendingDocs = allDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            final editStatus = (data['editApprovalStatus'] ?? '').toString().toLowerCase();
            return status == 'pending' || editStatus == 'pending';
          }).toList();

          if (pendingDocs.isEmpty) {
            return const Center(child: Text("No pending approvals"));
          }

          return ListView.builder(
            itemCount: pendingDocs.length,
            itemBuilder: (context, index) {
              final snapshotDoc = pendingDocs[index];
              final data = snapshotDoc.data() as Map<String, dynamic>;

              final propertyId = snapshotDoc.id;
              final propertyName = data["propertyName"] ?? data['pendingEdits']?['propertyName'] ?? "Property";
              final ownerId = data["ownerId"];

              final isNewSubmission = (data['status'] ?? '') == 'pending';
              final isEditRequest = (data['editApprovalStatus'] ?? '') == 'pending';

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(propertyName),
                  subtitle: Text(isEditRequest ? 'Edit request — ${data["city"] ?? ""}' : (data["city"] ?? "")),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () async {
                          // Approve either new submission or edit request
                          if (isNewSubmission) {
                            await approveProperty(propertyId, ownerId, propertyName);
                          } else if (isEditRequest) {
                            // Apply pending edits to the document
                            final docRef = FirebaseFirestore.instance.collection('properties').doc(propertyId);
                            final cur = await docRef.get();
                            final map = cur.data() as Map<String, dynamic>? ?? {};
                            final pending = map['pendingEdits'] as Map<String, dynamic>? ?? {};
                            if (pending.isNotEmpty) {
                              final updateMap = Map<String, dynamic>.from(pending);
                              updateMap['updatedAt'] = FieldValue.serverTimestamp();
                              await docRef.update(updateMap);
                            }
                            await docRef.update({
                              'editApprovalStatus': 'approved',
                              'editHandledAt': FieldValue.serverTimestamp(),
                              'pendingEdits': FieldValue.delete(),
                            });

                            // Notify owner
                            await FirebaseFirestore.instance.collection("notifications").add({
                              "title": "Property Edit Approved",
                              "message": "Your edits to \"$propertyName\" have been approved and applied.",
                              "userId": ownerId,
                              "type": "property_edit",
                              "status": "approved",
                              "isRead": false,
                              "createdAt": FieldValue.serverTimestamp(),
                            });
                          }
                        },
                        child: const Text("Approve"),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          if (isNewSubmission) {
                            await rejectProperty(propertyId, ownerId, propertyName);
                          } else if (isEditRequest) {
                            // mark edit as rejected
                            await FirebaseFirestore.instance.collection('properties').doc(propertyId).update({
                              'editApprovalStatus': 'rejected',
                              'editHandledAt': FieldValue.serverTimestamp(),
                            });

                            // Notify owner
                            await FirebaseFirestore.instance.collection("notifications").add({
                              "title": "Property Edit Rejected",
                              "message": "Sorry — your edits to \"$propertyName\" were not approved by admin.",
                              "userId": ownerId,
                              "type": "property_edit",
                              "status": "rejected",
                              "isRead": false,
                              "createdAt": FieldValue.serverTimestamp(),
                            });
                          }
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