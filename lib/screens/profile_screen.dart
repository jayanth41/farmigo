import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/owner_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(0, 78, 183, 113),
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildStatsCounter(),
            const SizedBox(height: 24),
            _buildSectionTitle('ACCOUNT'),
            _buildAccountSection(context),
            const SizedBox(height: 24),
            _buildSectionTitle('PAYMENT & REWARDS'),
            _buildPaymentAndRewardsSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('SUPPORT'),
            _buildSupportSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('SETTINGS'),
            _buildSettingsSection(),
            const SizedBox(height: 32),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Jayanth',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'jayanth@gmail.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Hyderabad',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Bookings', '12'),
        _buildStatItem('Favorites', '5'),
        _buildStatItem('Rewards', '1500'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & Security',
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndRewardsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Rewards & Offers',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.policy_outlined,
            title: 'Terms & Policies',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.settings_outlined,
            title: 'App Settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'LOGOUT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}