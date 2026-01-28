import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'How do I book a farmhouse?',
                answer:
                    'Browse properties, select your dates, review details, and complete checkout with your preferred payment method.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'What is your cancellation policy?',
                answer:
                    'Cancellations made 7 days before check-in are fully refundable. Late cancellations may incur charges.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'Can I modify my booking?',
                answer:
                    'Yes, you can modify dates and details up to 48 hours before check-in through your booking details page.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'Is there customer support available?',
                answer:
                    'Our support team is available 24/7 via chat, email, and phone to assist you.',
              ),
              const SizedBox(height: 12),
              _buildFAQItem(
                question: 'How are payments processed?',
                answer:
                    'We accept all major credit cards, debit cards, UPI, and digital wallets. Payments are secured with industry-standard encryption.',
              ),
              const SizedBox(height: 28),
              const Text(
                'Support Channels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildSupportCard(
                icon: Icons.chat,
                title: 'Live Chat',
                description: 'Chat with our support team instantly',
              ),
              const SizedBox(height: 12),
              _buildSupportCard(
                icon: Icons.email,
                title: 'Email Support',
                description: 'support@farmigo.com',
              ),
              const SizedBox(height: 12),
              _buildSupportCard(
                icon: Icons.phone,
                title: 'Phone Support',
                description: '+91 9876543210',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
