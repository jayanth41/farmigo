import 'package:flutter/material.dart';
import '../services/duffel_service.dart';

class FlightBookingScreen extends StatefulWidget {
  final String offerId;

  const FlightBookingScreen({super.key, required this.offerId});

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  String gender = 'male';
  DateTime? dob;

  bool loading = false;

  Future<void> _bookFlight() async {
    if (!_formKey.currentState!.validate() || dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final service = DuffelService();

      await service.createOrder(
        offerId: widget.offerId,
        passengerData: PassengerData(
          title: "Mr",
          firstName: firstNameCtrl.text.trim(),
          lastName: lastNameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          phoneNumber: phoneCtrl.text.trim(),
          dateOfBirth: "${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}",
          gender: gender,
        ),
        contactEmail: emailCtrl.text.trim(),
        contactPhoneNumber: phoneCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Success ✅")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (picked != null) {
      setState(() => dob = picked);
    }
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        validator: (v) {
          if (v == null || v.isEmpty) return "Required";

          if (label.toLowerCase().contains('email')) {
            if (!v.contains('@')) return "Enter valid email";
          }

          if (label.toLowerCase().contains('phone')) {
            if (v.length < 10) return "Enter valid phone";
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Passenger Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field("First Name", firstNameCtrl),
              _field("Last Name", lastNameCtrl),
              _field("Email", emailCtrl, type: TextInputType.emailAddress),
              _field("Phone (+91...)", phoneCtrl,
                  type: TextInputType.phone),

              /// Gender
              DropdownButtonFormField<String>(
                value: gender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text("Male")),
                  DropdownMenuItem(value: 'female', child: Text("Female")),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => gender = v);
                  }
                },
                decoration: const InputDecoration(labelText: "Gender"),
              ),

              const SizedBox(height: 12),

              if (dob == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Date of Birth is required",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              /// DOB
              ElevatedButton(
                onPressed: _pickDate,
                child: Text(
                  dob == null
                      ? "Select Date of Birth"
                      : "DOB: ${dob!.toLocal().toString().split(' ')[0]}",
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : _bookFlight,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Book Flight"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}