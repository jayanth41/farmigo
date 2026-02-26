import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reusable side menu component for all owner dashboards
class OwnerSideMenu extends StatelessWidget {
  final String? ownerName;
  final String? ownerEmail;
  final String? activeRole;
  final Function(String)? onRoleChange;
  final VoidCallback? onLogout;
  final String currentScreen; // "home" | "properties" | "reports" | "settings"

  const OwnerSideMenu({
    super.key,
    this.ownerName,
    this.ownerEmail,
    this.activeRole,
    this.onRoleChange,
    this.onLogout,
    required this.currentScreen,
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut().then((_) {
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              });
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRoleSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Role'),
        content: const Text('Select the role you want to switch to:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRoleChange?.call('farmhouse');
            },
            child: const Text('Farmhouse Owner'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRoleChange?.call('cOwner');
            },
            child: const Text('Co-Owner'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header with user info
          UserAccountsDrawerHeader(
            accountName: Text(ownerName ?? 'Owner Name'),
            accountEmail: Text(ownerEmail ?? 'email@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blue.shade300,
              child: Text(
                (ownerName?.isNotEmpty ?? false)
                    ? ownerName!.characters.first.toUpperCase()
                    : 'O',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard Home
                _buildMenuTile(
                  context,
                  icon: Icons.home,
                  label: 'Dashboard Home',
                  isActive: currentScreen == 'home',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentScreen != 'home') {
                      Navigator.pushReplacementNamed(context, '/owner_dashboard');
                    }
                  },
                ),

                // Properties
                _buildMenuTile(
                  context,
                  icon: Icons.domain,
                  label: 'Properties',
                  isActive: currentScreen == 'properties',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentScreen != 'properties') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/owner/properties',
                      );
                    }
                  },
                ),

                // Reports
                _buildMenuTile(
                  context,
                  icon: Icons.bar_chart,
                  label: 'Reports & Analytics',
                  isActive: currentScreen == 'reports',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentScreen != 'reports') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/owner/reports',
                      );
                    }
                  },
                ),

                // Settings
                _buildMenuTile(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  isActive: currentScreen == 'settings',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentScreen != 'settings') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/owner/settings',
                      );
                    }
                  },
                ),

                const Divider(margin: EdgeInsets.symmetric(vertical: 12)),

                // Switch Role (only for multi-owners)
                if (activeRole != null && activeRole != 'null')
                  _buildMenuTile(
                    context,
                    icon: Icons.swap_calls,
                    label: 'Switch Role',
                    onTap: () {
                      Navigator.pop(context);
                      _showRoleSelection(context);
                    },
                  ),
              ],
            ),
          ),

          // Logout button at bottom
          const Divider(margin: EdgeInsets.all(0)),
          _buildMenuTile(
            context,
            icon: Icons.logout,
            label: 'Logout',
            textColor: Colors.red,
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.blue : (textColor ?? Colors.grey),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.blue : (textColor ?? Colors.black),
        ),
      ),
      trailing: isActive
          ? Container(
        width: 4,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(2),
        ),
      )
          : null,
      onTap: onTap,
      selected: isActive,
      selectedTileColor: Colors.blue.withOpacity(0.1),
    );
  }
}
