import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_property_screen.dart';

class OwnerPropertiesScreen extends StatefulWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  State<OwnerPropertiesScreen> createState() => _OwnerPropertiesScreenState();
}

class _OwnerPropertiesScreenState extends State<OwnerPropertiesScreen> {
  List properties = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProperties();
  }

  Future<void> fetchProperties() async {
    // Backend for owner properties removed during migration. Keep an empty
    // list so the UI remains stable. Implement Firestore-based fetching
    // here when ready.
    setState(() {
      properties = [];
      loading = false;
    });
  }

  Future<void> deleteProperty(String id) async {
    // Not implemented in Firebase-only migration.
    debugPrint('deleteProperty called for $id (not implemented)');
    await fetchProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Properties"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddPropertyScreen(),
                ),
              );
              fetchProperties(); // refresh after add
            },
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : properties.isEmpty
              ? const Center(child: Text("No properties added yet"))
              : ListView.builder(
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final p = properties[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(p['title']),
                        subtitle: Text(p['location']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                // Edit later
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await deleteProperty(p['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
