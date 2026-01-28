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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Company Info Section
              _buildSection(
                title: 'About Farmigo',
                content:
                    'Farmigo is a leading platform for discovering and booking premium farmhouses, villas, and rural getaways. We connect travelers with authentic countryside experiences.',
              ),
              const SizedBox(height: 24),
              // Mission Section
              _buildSection(
                title: 'Our Mission',
                content:
                    'To provide seamless access to beautiful rural properties while supporting local communities and sustainable tourism practices.',
              ),
              const SizedBox(height: 24),
              // Vision Section
              _buildSection(
                title: 'Our Vision',
                content:
                    'To be the most trusted platform for rural hospitality, offering memorable experiences at every step of the journey.',
              ),
              const SizedBox(height: 24),
              // Contact Section
              const Text(
                'Get in Touch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildContactItem(
                icon: Icons.email,
                label: 'Email',
                value: 'support@farmigo.com',
              ),
              const SizedBox(height: 12),
              _buildContactItem(
                icon: Icons.phone,
                label: 'Phone',
                value: '+91 9876543210',
              ),
              const SizedBox(height: 12),
              _buildContactItem(
                icon: Icons.location_on,
                label: 'Address',
                value: 'Bangalore, India',
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

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
