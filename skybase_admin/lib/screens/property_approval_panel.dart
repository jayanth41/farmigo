import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Admin panel for property approvals. Shows two tabs:
///  - New Properties: documents with `status == 'pending'`
///  - Edited Properties: documents with `editApprovalStatus == 'pending'`
///
/// For edited properties we show a simple field-level diff between the
/// live document and `pendingEdits` so admins can see what the owner changed.
class PropertyApprovalPanel extends StatefulWidget {
  const PropertyApprovalPanel({super.key});

  @override
  State<PropertyApprovalPanel> createState() => _PropertyApprovalPanelState();
}

class _PropertyApprovalPanelState extends State<PropertyApprovalPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveNew(String propertyId, String ownerId, String name) async {
    final docRef = FirebaseFirestore.instance.collection('properties').doc(propertyId);
    await docRef.update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Property Approved',
      'message': 'Your property "$name" has been approved.',
      'userId': ownerId,
      'type': 'property_status',
      'status': 'approved',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rejectNew(String propertyId, String ownerId, String name) async {
    final docRef = FirebaseFirestore.instance.collection('properties').doc(propertyId);
    await docRef.update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Property Rejected',
      'message': 'Your property "$name" has been rejected.',
      'userId': ownerId,
      'type': 'property_status',
      'status': 'rejected',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _approveEdit(String propertyId, String ownerId, String name) async {
    final docRef = FirebaseFirestore.instance.collection('properties').doc(propertyId);
  final cur = await docRef.get();
  final map = cur.data() ?? {};
    final pending = (map['pendingEdits'] as Map<String, dynamic>?) ?? {};

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

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Property Edit Approved',
      'message': 'Your edits to "$name" have been approved and applied.',
      'userId': ownerId,
      'type': 'property_edit',
      'status': 'approved',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rejectEdit(String propertyId, String ownerId, String name) async {
    final docRef = FirebaseFirestore.instance.collection('properties').doc(propertyId);
    await docRef.update({
      'editApprovalStatus': 'rejected',
      'editHandledAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Property Edit Rejected',
      'message': 'Sorry — your edits to "$name" were not approved by admin.',
      'userId': ownerId,
      'type': 'property_edit',
      'status': 'rejected',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Build a list of widgets showing differences between `current` and `pending`.
  /// Fields present in `pending` are shown; if value differs we show A -> B.
  List<Widget> _buildDiff(Map<String, dynamic> current, Map<String, dynamic> pending) {
    // Collect all keys but prefer ordering from pending (owner-edits)
    final keys = <String>[];
    keys.addAll(pending.keys.whereType<String>());
    for (final k in current.keys) {
      if (!keys.contains(k)) keys.add(k);
    }

    final rows = <Widget>[];

    String _formatVal(dynamic v) {
      if (v == null) return '-';
      if (v is String) return v;
      if (v is num || v is bool) return v.toString();
      if (v is List) return v.map((e) => e?.toString() ?? '-').join(', ');
      if (v is Map) return jsonEncode(v);
      return v.toString();
    }

    for (final k in keys) {
      if (k == 'updatedAt' || k == 'createdAt' || k == 'id' || k == 'photoUrls' || k == 'pendingEdits') continue;
      final curVal = current[k];
      final penVal = pending[k];
      if (penVal == null) continue; // only display fields that owner edited

      final curStr = _formatVal(curVal);
      final penStr = _formatVal(penVal);

      Widget row;
      if (curVal == null) {
        // New field set by owner
        row = Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            Expanded(child: Text('Set to: $penStr', style: const TextStyle(color: Colors.black87))),
          ]),
        );
      } else if (curVal != penVal) {
        // Changed from X to Y
        row = Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text('From: $curStr', style: const TextStyle(color: Colors.grey))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.arrow_downward, size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(child: Text('To: $penStr', style: const TextStyle(color: Colors.black87))),
            ]),
          ]),
        );
      } else {
        // Present but unchanged (rare) — show value
        row = Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            Expanded(child: Text(_formatVal(penVal), style: const TextStyle(color: Colors.black87))),
          ]),
        );
      }

      rows.add(row);
    }

    if (rows.isEmpty) {
      rows.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No visible field changes found.'),
      ));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Approvals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'New Properties'), Tab(text: 'Edited Properties')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // NEW PROPERTIES
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('properties')
                .where('status', isEqualTo: 'pending')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No new properties pending approval'));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data() as Map<String, dynamic>;
                  final name = data['propertyName'] ?? 'Property';
                  final ownerId = data['ownerId'] as String?;

                  return Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('${data['city'] ?? ''} • ${data['propertyType'] ?? ''}'),
                        const SizedBox(height: 8),
                        Row(children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () async {
                              await _approveNew(d.id, ownerId ?? '', name);
                            },
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              await _rejectNew(d.id, ownerId ?? '', name);
                            },
                            child: const Text('Reject'),
                          ),
                        ])
                      ]),
                    ),
                  );
                },
              );
            },
          ),

          // EDITED PROPERTIES
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('properties')
                .where('editApprovalStatus', isEqualTo: 'pending')
                .orderBy('editRequestedAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No edited properties pending approval'));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data() as Map<String, dynamic>;
                  final ownerId = data['ownerId'] as String? ?? '';
                  final name = data['propertyName'] ?? data['pendingEdits']?['propertyName'] ?? 'Property';
                  final pending = (data['pendingEdits'] as Map<String, dynamic>?) ?? {};

                  return Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('Requested ${data['editRequestedAt'] ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ]),
                        const SizedBox(height: 8),

                        // Diff area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('properties').doc(d.id).get(),
                            builder: (context, curSnap) {
                              if (!curSnap.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                              final cur = curSnap.data!.data() as Map<String, dynamic>? ?? {};
                              final diff = _buildDiff(cur, pending);
                              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: diff);
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                        Row(children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () async {
                              await _approveEdit(d.id, ownerId, name);
                            },
                            child: const Text('Approve Edits'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              await _rejectEdit(d.id, ownerId, name);
                            },
                            child: const Text('Reject Edits'),
                          ),
                        ])
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
