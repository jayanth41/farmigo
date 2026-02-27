import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  int properties = 0;
  int uniqueCities = 0;
  int owners = 0;
  int happyGuests = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final propsSnap = await FirebaseFirestore.instance.collection('properties').get();
      final bookingsSnap = await FirebaseFirestore.instance.collection('bookings').get();

  final cities = <String>{};
      final ownersSet = <String>{};

      for (final d in propsSnap.docs) {
        final data = d.data();
        final city = (data['city'] ?? data['location'] ?? '')?.toString() ?? '';
        final ownerId = (data['ownerId'] ?? data['owner'] ?? '')?.toString() ?? '';
        if (city.isNotEmpty) cities.add(city);
        if (ownerId.isNotEmpty) ownersSet.add(ownerId);
      }

      final guestsSet = <String>{};
      for (final d in bookingsSnap.docs) {
        final data = d.data();
        final guestId = (data['guestId'] ?? data['userId'] ?? '')?.toString() ?? '';
        if (guestId.isNotEmpty) guestsSet.add(guestId);
      }

      setState(() {
        properties = propsSnap.size;
        uniqueCities = cities.length;
        owners = ownersSet.length;
        happyGuests = guestsSet.length;
        loading = false;
      });
    } catch (e) {
      debugPrint('[AboutUs] failed to load stats: $e');
      setState(() => loading = false);
    }
  }

  Widget _statCard(String label, int value, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              builder: (context, val, child) => Text('$val', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('About Skybase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'Skybase is a platform for discovering and booking farmhouses, villas, and unique rural stays. We connect property owners and guests while promoting local tourism.',
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              const Text('Our impact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _statCard('Properties', properties, Theme.of(context).colorScheme.primary),
                    _statCard('Cities', uniqueCities, Colors.teal),
                    _statCard('Owners', owners, Colors.deepPurple),
                    _statCard('Happy guests', happyGuests, Colors.orange),
                  ],
                ),

              const SizedBox(height: 28),
              const Text('Get in Touch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Contact details will be available soon.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
