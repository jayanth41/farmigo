import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/farmhouse_owner_dashboard.dart';
import '../screens/car_owner_dashboard_new.dart';

/// Reusable app drawer with role switching and logout functionality
class AppDrawerWithRoles extends StatefulWidget {
  final String uid;

  const AppDrawerWithRoles({
    super.key,
    required this.uid,
  });

  @override
  State<AppDrawerWithRoles> createState() => _AppDrawerWithRolesState();
}

class _AppDrawerWithRolesState extends State<AppDrawerWithRoles> {
  bool _isLoading = false;
  List<String> _roles = [];
  String? _activeRole;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await AuthService.getUserRoles(widget.uid);
      final activeRole = await AuthService.getActiveRole(widget.uid);
      debugPrint('[AppDrawer] Loaded roles: $roles, activeRole: $activeRole, roles.length: ${roles.length}');
      setState(() {
        _roles = roles;
        _activeRole = activeRole;
      });
    } catch (e) {
      debugPrint('[AppDrawer] Error loading roles: $e');
    }
  }

  Future<void> _switchRole(String role) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.setActiveRole(widget.uid, role);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close drawer

      // Navigate to appropriate dashboard
      Widget dashboard;
      switch (role) {
        case 'farmhouse_owner':
          dashboard = const FarmhouseOwnerDashboard();
          break;
        case 'car_owner':
          dashboard = const CarOwnerDashboard();
          break;
        default:
          debugPrint('[AppDrawer] Unknown role: $role');
          return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => dashboard),
      );
    } catch (e) {
      debugPrint('[AppDrawer] Error switching role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _enrollAsAnotherOwner() async {
    // This would typically open a property enrollment flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Property enrollment flow coming soon'),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 56,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Property Owner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_activeRole != null)
                    Text(
                      _activeRole!.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),
            // Role-specific options - only show for multi-role users
            if (_roles.length > 1) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'SWITCH ROLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              for (final role in _roles)
                _buildRoleMenuItem(role),
            ],
            const Divider(),
            // Home option
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: _isLoading ? null : () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            const Divider(),
            // Enroll as another property owner
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Enroll as Another Property Owner'),
              onTap: _isLoading ? null : _enrollAsAnotherOwner,
            ),
            const Divider(),
            // Settings
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings screen coming soon'),
                        ),
                      );
                    },
            ),
            // Logout
            ListTile(
              leading: const Icon(Icons.logout_outlined, color: Colors.red),
              title: const Text('Logout'),
              onTap: _isLoading ? null : _showLogoutConfirmation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleMenuItem(String role) {
    final isActive = _activeRole == role;
    final displayName = role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    final icon = role == 'farmhouse_owner'
        ? Icons.house_outlined
        : role == 'car_owner'
            ? Icons.directions_car_outlined
            : Icons.dashboard_outlined;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.blue : null,
      ),
      title: Text(
        'Switch to $displayName',
        style: isActive
            ? const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              )
            : null,
      ),
      trailing: isActive
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      enabled: !_isLoading,
      onTap: isActive
          ? null
          : () => _switchRole(role),
    );
  }
}
