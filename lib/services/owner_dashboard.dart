import 'package:flutter/material.dart';
import '../services/owner_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final service = OwnerService();
  List bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    final data = await service.fetchOwnerBookings();
    setState(() {
      bookings = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Owner Dashboard")),
      body: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final b = bookings[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(b['properties']['title']),
              subtitle: Text(
                "Visit: ${b['visit_date']} \nStatus: ${b['status']}",
              ),
              trailing: b['status'] == 'pending'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await service.updateBookingStatus(
                                b['id'], 'approved');
                            loadBookings();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await service.updateBookingStatus(
                                b['id'], 'rejected');
                            loadBookings();
                          },
                        ),
                      ],
                    )
                  : Text(
                      b['status'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          );
        },
      ),
    );
  }
}
