import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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

      for (final d in propsSnap.docs) {
        final data = d.data();
        final city = (data['city'] ?? data['location'] ?? '')?.toString() ?? '';
        
        if (city.isNotEmpty) cities.add(city);

      }
            // 🔥 FIX: Fetch owners from users collection instead of properties
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final ownersSet = <String>{};
      final guestsSet = <String>{};

      for (final d in usersSnap.docs) {
        final data = d.data();

        // Check role OR roles array
        final role = data['role'];
        final roles = data['roles'];

        if (role == 'owner' ||
            (roles is List && roles.contains('farmhouse_owner'))) {
          ownersSet.add(d.id);
        }

        // 🔥 FIX: Happy guests = all non-owner users
        final roleStr = (role ?? '').toString().toLowerCase();

        bool isOwnerUser = false;

        if (roleStr.contains('owner')) {
          isOwnerUser = true;
        }

        if (roles is List) {
          for (final r in roles) {
            if (r.toString().toLowerCase().contains('owner')) {
              isOwnerUser = true;
              break;
            }
          }
        }

        // If NOT owner → count as happy guest
        if (!isOwnerUser) {
          guestsSet.add(d.id);
        }
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
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {},
    child: Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 41, 70, 92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              builder: (context, val, child) => Text(
                '$val',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Text('About Us'),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
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
             Text(
                'Skybase is a platform for discovering and booking farmhouses, villas, and unique rural stays. We connect property owners and guests while promoting local tourism.',
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),

              const Text('Our impact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (properties == 0)
                const Center(child: Text('No data available'))
              else
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _statCard('Properties', properties, Colors.white),
                    _statCard('Cities', uniqueCities, Colors.white),
                    _statCard('Owners', owners, Colors.white),
                    _statCard('Happy guests', happyGuests, Colors.white),
                  ],
                ),

              const SizedBox(height: 28),
              const Text('Get in Touch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF29465C),
        Color(0xFF3A6D8C),
      ],
    ),
    boxShadow: const [
      BoxShadow(
        color: Colors.black38,
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title & subtitle
      const Text('Skybase Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 6),
      const Text('Need help? Reach out anytime.', style: TextStyle(fontSize: 14, height: 1.4, color: Colors.white70)),

      const SizedBox(height: 16),

      // Contact items
      Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Email row
            InkWell(
              onTap: () => _launchEmail(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.email_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Email text (wraps)
                    Expanded(
                      child: Text(
                        'support@skybase.com',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),

            // Divider
            Container(
              height: 1,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.white24,
            ),

            // Phone row
            InkWell(
              onTap: () => _launchPhone(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.phone_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '+91 63030 91715',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      // CTA buttons
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _launchPhone(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Call',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _launchEmail(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Email',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+916303091715');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint('Could not launch dialer');
    }
  }

  void _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@skybase.com',
      query: 'subject=Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      debugPrint('Could not launch email');
    }
  }
}
