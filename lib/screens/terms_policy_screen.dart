import 'package:flutter/material.dart';

class TermsPolicyScreen extends StatefulWidget {
  const TermsPolicyScreen({super.key});

  @override
  State<TermsPolicyScreen> createState() => _TermsPolicyScreenState();
}

class _TermsPolicyScreenState extends State<TermsPolicyScreen>
    with SingleTickerProviderStateMixin {
  final bool _accepted = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 41, 70, 92),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Text(
                        'Terms & Policies',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Terms'),
                    Tab(text: 'Privacy'),
                    Tab(text: 'Refund'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsTab(),
          _buildPrivacyTab(),
          _buildRefundTab(),
        ],
      ),
    );
  }

  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionTitle('Acceptance of Terms'),
          _buildSectionContent(
            'By accessing or using SkyBase, you agree to be bound by these Terms and Conditions. This agreement applies to both Users (Guests) and Property Owners. If you do not agree with any part of these terms, you must discontinue use of the platform immediately.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('User & Owner Responsibilities'),
          _buildSectionContent(
            'Users must provide accurate personal and booking information. Property Owners must provide truthful property descriptions, pricing, and availability details. Fake listings, misleading information, or fraudulent activity are strictly prohibited. SkyBase reserves the right to suspend or terminate accounts that violate platform policies.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Bookings & Platform Role'),
          _buildSectionContent(
            'SkyBase acts solely as a digital platform connecting Users and Property Owners. We do not own, manage, or control listed properties. All bookings are subject to availability and owner approval where applicable. SkyBase is not responsible for property condition, disputes between parties, or third-party service failures.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Account Suspension & Termination'),
          _buildSectionContent(
            'SkyBase may suspend or permanently terminate accounts involved in fraud, abuse, policy violations, payment manipulation, or illegal activities. Repeated cancellations or misuse of platform features may also result in account restrictions.',
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionTitle('Information We Collect'),
          _buildSectionContent(
            'We collect information such as name, email address, phone number, booking details, property information, chat messages, and device data. Firebase services are used for authentication, database storage, and notifications.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('How We Use Your Data'),
          _buildSectionContent(
            'Your information is used to process bookings, manage listings, enable communication between Users and Owners, send notifications, and improve platform functionality. We do not sell personal data to third parties.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Data Security & Retention'),
          _buildSectionContent(
            'All data is securely stored using trusted cloud infrastructure. We implement reasonable technical safeguards to protect user information. Users may request account deletion, and associated personal data will be removed in accordance with applicable policies.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Notifications & Tracking'),
          _buildSectionContent(
            'SkyBase may use push notifications to inform users about bookings, messages, or updates. Basic analytics may be used to enhance user experience and app performance.',
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildRefundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionTitle('Cancellation & Refund Policy'),
          _buildSectionContent(
            'Refund eligibility depends on the cancellation timing and the specific property’s policy. Users are encouraged to review cancellation terms before confirming a booking.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Standard Refund Timeline'),
          _buildSectionContent(
            '7 or more days before check-in: 90% refund.\n3 to 6 days before check-in: 80% refund.\nLess than 3 days before check-in: 70% refund .\nRefunds are processed within 5–7 business days depending on payment provider timelines.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Dispute Resolution'),
          _buildSectionContent(
            'In case of booking disputes, users must contact support within 24 hours of check-in. SkyBase will review available evidence and facilitate a fair resolution between both parties. Final decisions are made at SkyBase’s discretion.',
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          height: 1.9,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}
