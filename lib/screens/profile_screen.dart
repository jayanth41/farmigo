import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/session_service.dart';
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

  final SupabaseClient supabase = Supabase.instance.client;

  File? _profileImage;

  final TextEditingController nameController =
      TextEditingController(text: "Jayanth");
  final TextEditingController emailController =
      TextEditingController(text: "jayanth@gmail.com");
  final TextEditingController cityController =
      TextEditingController(text: "Hyderabad");
  final TextEditingController phoneController =
      TextEditingController(text: "9876543210");

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
    phoneController.dispose();
    super.dispose();
  }

  // ---------------- IMAGE PICK ----------------

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildStatsCounter(),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleEdit,
                icon: Icon(showEdit ? Icons.close : Icons.edit),
                label: Text(showEdit ? "Close Edit" : "Edit Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

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

  // ---------------- HEADER ----------------

  Widget _buildProfileHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickImage,
      child: CircleAvatar(
      radius: 42,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage:
        _profileImage != null ? FileImage(_profileImage!) : null,
      child: _profileImage == null
        ? Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.onPrimary)
        : null,
      ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      Text(nameController.text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
      Text(emailController.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 4),
      Text(cityController.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14)),
      ],
    );
  }

  // ---------------- EDIT FORM ----------------

  Widget _buildEditProfileForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTextField("Name", nameController),
          _buildTextField("Phone", phoneController),
          _buildTextField("City", cityController),

          TextField(
            controller: emailController,
            enabled: false,
            decoration: InputDecoration(
              labelText: "Email",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

  // ---------------- SAVE PROFILE ----------------

  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').update({
      'name': nameController.text,
      'city': cityController.text,
      'phone': phoneController.text,
    }).eq('id', user.id);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Updated")),
    );
  }

  // ---------------- DELETE ACCOUNT ----------------

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
        label: Text("Delete Account", style: TextStyle(color: Theme.of(context).colorScheme.error)),
        onPressed: _showDeleteWarning,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.error),
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
            "Are you sure you want to permanently delete your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: _deleteAccount,
            child:
                const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').delete().eq('id', user.id);
    // Use central AuthController for sign out
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      await auth.signOut();
    } catch (_) {}

    try {
      await SessionService.clear();
    } catch (_) {}
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  // ---------------- LOGOUT ----------------

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            final auth = Provider.of<AuthController>(context, listen: false);
            await auth.signOut();
          } catch (_) {}
          try {
            await SessionService.clear();
          } catch (_) {}
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child:
            const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
