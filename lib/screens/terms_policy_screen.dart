import 'package:flutter/material.dart';

class TermsPolicyScreen extends StatefulWidget {
  const TermsPolicyScreen({super.key});

  @override
  State<TermsPolicyScreen> createState() => _TermsPolicyScreenState();
}

class _TermsPolicyScreenState extends State<TermsPolicyScreen>
    with SingleTickerProviderStateMixin {
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
      appBar: AppBar(
        title: const Text('Terms & Policies'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelColor: colorScheme.primary,
          unselectedLabelColor: onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Terms'),
            Tab(text: 'Privacy'),
            Tab(text: 'Refund'),
          ],
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
          _buildSectionTitle('Terms of Service'),
          _buildSectionContent(
            'By using Farmigo, you agree to comply with these terms and conditions. '
            'You must be at least 18 years old to book properties on our platform. '
            'All bookings are subject to property availability and host approval.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('User Responsibilities'),
          _buildSectionContent(
            'Users are responsible for providing accurate information during booking. '
            'Guests must follow house rules and respect property facilities. '
            'Unauthorized parties or commercial activities are strictly prohibited.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Payment Terms'),
          _buildSectionContent(
            'Payment must be completed before check-in. We accept various payment methods. '
            'All transactions are final unless cancellation policy applies. '
            'Farmigo is not responsible for third-party payment failures.',
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
          _buildSectionTitle('Privacy Policy'),
          _buildSectionContent(
            'We collect personal information necessary for booking and communication. '
            'Your data is encrypted and stored securely on our servers. '
            'We do not share your information with third parties without consent.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Data Collection'),
          _buildSectionContent(
            'We collect name, email, phone, and payment details. '
            'Usage analytics help us improve our platform. '
            'You can request data deletion at any time.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Cookies & Tracking'),
          _buildSectionContent(
            'We use cookies to enhance user experience and provide personalized content. '
            'You can disable cookies in your browser settings. '
            'Third-party analytics may be used to understand platform usage.',
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
          _buildSectionTitle('Refund Policy'),
          _buildSectionContent(
            'Refunds are processed based on cancellation timing and property policies. '
            'Cancellations 7+ days before check-in are fully refundable. '
            'Late cancellations may incur charges as per property policy.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Refund Timeline'),
          _buildSectionContent(
            '7+ days before check-in: 100% refund\n'
            '3-7 days before check-in: 50% refund\n'
             'Less than 3 days: No refund (non-refundable booking)\n'
            'Refunds are processed within 5-7 business days.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Issue Resolution'),
          _buildSectionContent(
            'Contact support within 24 hours of check-in for any issues. '
            'We will investigate and provide appropriate compensation if applicable. '
            'All disputes will be resolved fairly based on evidence.',
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
