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
          _buildContactSection(),
          const SizedBox(height: 20),
          _buildFaqSection(),
          const SizedBox(height: 20),
          _buildLearningResources(),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
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
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: "Search for help...",
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
            ),
          )
        ],
      ),
    );
  }

  // 🔹 Contact cards
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Contact Us",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _contactTile(Icons.chat, "Live Chat", "Chat with our support team"),
        _contactTile(Icons.call, "Call Us", "+1 (800) 123-4567"),
        _contactTile(Icons.email, "Email Support", "support@farmigo.com"),
      ],
    );
  }

  Widget _contactTile(IconData icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
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
  Widget _buildLearningResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Learning Resources",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _resourceTile(Icons.menu_book, "User Guide", "Learn how to use the app"),
        _resourceTile(
            Icons.video_library, "Video Tutorials", "Watch step-by-step guides"),
      ],
    );
  }

  Widget _resourceTile(IconData icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  // 🔹 Support hours
  Widget _buildSupportHours() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
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
