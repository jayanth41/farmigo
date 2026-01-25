import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchOwnerBookings() async {
    final data = await supabase
        .from('bookings')
        .select('''
          id,
          visit_date,
          status,
          properties(title)
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateBookingStatus(
      String bookingId, String status) async {
    await supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId);
  }
}
