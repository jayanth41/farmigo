import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 41, 70, 92),
                  Color.fromARGB(255, 32, 58, 67),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const Text(
                          "Help & Support",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We're here to help you 24/7",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 24),
                _buildContactSection(context),
                const SizedBox(height: 20),
                _buildFaqSection(),
                const SizedBox(height: 20),
                _buildSupportHours(),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
          colors: [const Color.fromARGB(255, 41, 70, 92), const Color.fromARGB(255, 41, 70, 92)],
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
        _contactTile(context, Icons.chat, "Chat Now", "Talk to our admin instantly"),
        _contactTile(context, Icons.call, "Call Us", "6303091715"),
        _contactTile(context, Icons.email, "Email Support", "support@skybase.co.in"),
      ],
    );
  }

  Widget _contactTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 41, 70, 92),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          if (title == "Chat Now") {
            // Use Get for navigation (GetMaterialApp routes)
            Get.toNamed('/adminChat');
          } else if (title == "Call Us") {
            final uri = Uri.parse("tel:6303091715");
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          } else if (title == "Email Support") {
            final uri = Uri.parse("mailto:support@skybase.co.in");
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
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

  // 🔹 Support hours
  Widget _buildSupportHours() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 41, 70, 92),
        borderRadius: BorderRadius.circular(12),
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "24/7 Customer Support",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "We are available round the clock to help you.",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.facebook,
                color: Color(0xFF1877F2), // Facebook Blue
                size: 28,
              ),
              const SizedBox(width: 24),
              const FaIcon(
                FontAwesomeIcons.instagram,
                color: Color(0xFFE1306C),
                size: 26,
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse("http://skybase.co.in/");
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
