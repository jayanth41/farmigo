import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool showEdit = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  final TextEditingController nameController =
      TextEditingController(text: "Jayanth");
  final TextEditingController emailController =
      TextEditingController(text: "jayanth@gmail.com");
  final TextEditingController cityController =
      TextEditingController(text: "Hyderabad");

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _toggleEdit() {
    setState(() {
      showEdit = !showEdit;
      showEdit ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    emailController.dispose();
    cityController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildStatsCounter(),
            const SizedBox(height: 20),

            // EDIT PROFILE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleEdit,
                icon: Icon(showEdit ? Icons.close : Icons.edit),
                label: Text(showEdit ? "Close Edit" : "Edit Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // EDIT PROFILE DROPDOWN
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: -1,
              child: _buildEditProfileForm(),
            ),

            const SizedBox(height: 20),

            _buildDeleteAccountButton(),
            const SizedBox(height: 12),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _buildProfileHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nameController.text,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(emailController.text,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(cityController.text,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("Bookings", "12"),
        _buildStatItem("Favorites", "5"),
        _buildStatItem("Rewards", "1500"),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // ---------------- EDIT FORM ----------------

  Widget _buildEditProfileForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTextField("Name", nameController),
          _buildTextField("Email", emailController),
          _buildTextField("City", cityController),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile Updated")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Save Changes"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ---------------- DELETE ACCOUNT ----------------

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete, color: Colors.red),
        label: const Text("Delete Account",
            style: TextStyle(color: Colors.red)),
        onPressed: _showDeleteWarning,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  void _showDeleteWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to permanently delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account deleted (demo)")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------------- LOGOUT ----------------

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text("LOGOUT",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
