import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
              // Company Info Section
              _buildSection(
                title: 'About Farmigo',
                content:
                    'Farmigo is a leading platform for discovering and booking premium farmhouses, villas, and rural getaways. We connect travelers with authentic countryside experiences.',
              ),
              const SizedBox(height: 28),
              // Mission Section
              _buildSection(
                title: 'Our Mission',
                content:
                    'To provide seamless access to beautiful rural properties while supporting local communities and sustainable tourism practices.',
              ),
              const SizedBox(height: 28),
              // Vision Section
              _buildSection(
                title: 'Our Vision',
                content:
                    'To be the most trusted platform for rural hospitality, offering memorable experiences at every step of the journey.',
              ),
              const SizedBox(height: 28),
              // Contact Section (placeholder)
              const Text(
                'Get in Touch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Contact items removed - replaced by a placeholder message above.
}
