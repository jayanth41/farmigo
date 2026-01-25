import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import 'owner_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, dynamic> userData = {
    'name': 'Jayanth',
    'email': 'jayanth@gmail.com',
    'phone': '9908863899',
    'location': 'Hyderabad',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 20),

            /// PROFILE INFO
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 10),

            Text(userData['name'],
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            /// SETTINGS
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  _settingsTile(
                    icon: Icons.notifications,
                    title: "Notifications",
                    onTap: () {},
                  ),

                  _settingsTile(
                    icon: Icons.security,
                    title: "Security",
                    onTap: () {},
                  ),

                  /// ✅ OWNER DASHBOARD BUTTON
                  _settingsTile(
                    icon: Icons.dashboard,
                    title: "Owner Dashboard",
                    onTap: () async {
                      final user =
                          Supabase.instance.client.auth.currentUser;

                      if (user == null) return;

                      final data = await Supabase.instance.client
                          .from('users')
                          .select('role')
                          .eq('id', user.id)
                          .single();

                      if (data['role'] == 'owner') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>  OwnerDashboard(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You are not an owner'),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
