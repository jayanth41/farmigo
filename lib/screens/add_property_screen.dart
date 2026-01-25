import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();

  bool _loading = false;

Future<void> _saveProperty() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final priceValue = int.tryParse(_price.text.trim());

    if (priceValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid price")),
      );
      return;
    }

    await Supabase.instance.client.from('properties').insert({
      'owner_id': user.id,
      'title': _title.text.trim(),
      'location': _location.text.trim(),
      'price': int.parse(_price.text.trim()),
      'description': _description.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Property added successfully")),
    );

    Navigator.pop(context);
  } catch (e) {
    print("SAVE ERROR: $e");
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Property")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: _location, decoration: const InputDecoration(labelText: "Location")),
            TextField(
              controller: _price,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:  _saveProperty,
              child: const Text("Save Property"),
            ),
          ],
        ),
      ),
    );
  }
}
