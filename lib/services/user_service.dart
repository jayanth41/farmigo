import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _client = Supabase.instance.client;

  /// Create a user profile row if one doesn't exist for the authenticated user.
  Future<void> createUserIfNotExists({required String name, required String phone, String role = 'user'}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await _client.from('users').select().eq('id', user.id).maybeSingle();
      if (existing == null) {
        await _client.from('users').insert({
          'id': user.id,
          'name': name,
          'phone': phone,
          'role': role,
        }).select();
      }
    } catch (e) {
      // swallow errors in create helper; callers may log if needed
      // debugPrint('createUserIfNotExists error: $e');
    }
  }

  /// Fetch the current user's profile row from `users` table.
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // Use maybeSingle() so we don't throw if the row doesn't exist.
      final data = await _client.from('users').select().eq('id', user.id).maybeSingle();
      if (data == null) return null;
      // Ensure we return a Map<String,dynamic>
      return Map<String, dynamic>.from(data);
    } catch (e) {
      // Log the error for easier debugging and return null.
      // Caller should handle null as 'no profile'.
      print('UserService.fetchUserProfile error: $e');
      return null;
    }
  }

  /// Update the current user's profile row.
  Future<bool> updateProfile({required String name, required String phone}) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('users').update({
        'name': name,
        'phone': phone,
      }).eq('id', user.id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
