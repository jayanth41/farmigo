import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildContactSection(context),
          const SizedBox(height: 20),
          _buildFaqSection(),
          const SizedBox(height: 20),
          _buildLearningResources(context),
          const SizedBox(height: 20),
          _buildSupportHours(),
        ],
      ),
    );
  }

  // 🔹 Header with search
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                "Help & Support",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "We're here to help you",
            style: TextStyle(color: Colors.white70),
          ),
          // Search bar removed to simplify header
          SizedBox(height: 4),
        ],
      ),
    );
  }

  // 🔹 Contact cards
  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Contact Us",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _contactTile(context, Icons.chat, "Live Chat", "Chat with our support team"),
        _contactTile(context, Icons.call, "Call Us", "Coming soon"),
        _contactTile(context, Icons.email, "Email Support", "Coming soon"),
      ],
    );
  }

  Widget _contactTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(title),
              content: const Text('This feature is coming soon.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔹 FAQ section
  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Frequently Asked Questions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _faqTile("How do I cancel my booking?",
            "You can cancel your booking from the 'My Bookings' section."),
        _faqTile("What payment methods are accepted?",
            "We accept cards, UPI, net banking and wallets."),
        _faqTile("How do I get a refund?",
            "Refunds are processed within 5-7 business days."),
        _faqTile("Is my payment information secure?",
            "Yes, we use industry-standard encryption."),
      ],
    );
  }

  Widget _faqTile(String question, String answer) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(question),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(answer),
          )
        ],
      ),
    );
  }

  // 🔹 Learning resources
  Widget _buildLearningResources(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Learning Resources",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _resourceTile(context, Icons.menu_book, "User Guide", "Learn how to use the app"),
        _resourceTile(context, Icons.video_library, "Video Tutorials", "Watch step-by-step guides"),
      ],
    );
  }

  Widget _resourceTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showNoticeItem(context, title),
      ),
    );
  }

  void _showNoticeItem(BuildContext context, String title) {
    final message = title == 'User Guide'
        ? 'User guide will be available soon.'
        : title == 'Video Tutorials'
            ? 'Tutorial videos coming soon.'
            : 'Coming soon.';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  // 🔹 Support hours
  Widget _buildSupportHours() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Support Hours",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Monday - Friday: 8:00 AM - 8:00 PM"),
          Text("Saturday: 9:00 AM - 6:00 PM"),
          Text("Sunday: 10:00 AM - 4:00 PM"),
        ],
      ),
    );
  }
}
