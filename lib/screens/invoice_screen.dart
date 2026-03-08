import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/car_booking.dart';

class InvoiceService {

  static Future<void> generateInvoice({
    required String bookingId,
    required String propertyName,
    required String location,
    required String checkIn,
    required String checkOut,
    required double totalPrice,
    required String userEmail,
    required String guestName,
    required String guestPhone,
    String? propertyImage,
  }) async {

    final pdf = pw.Document();

    // Preload image bytes outside the page builder so we don't use `await`
    // inside the synchronous page-builder callback. Use a simple HTTP GET to
    // fetch raw bytes which we can pass to pw.MemoryImage.
    Uint8List? imageBytes;
    if (propertyImage != null) {
      try {
        final uri = Uri.parse(propertyImage);
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          imageBytes = resp.bodyBytes;
        } else {
          debugPrint('Failed to fetch invoice image, status: ${resp.statusCode}');
          imageBytes = null;
        }
      } catch (e) {
        debugPrint('Failed to load property image for invoice: $e');
        imageBytes = null;
      }
    }

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              /// SKYBASE HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Skybase",
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Invoice #$bookingId",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              /// PROPERTY IMAGE
              if (imageBytes != null)
                pw.Container(
                  height: 160,
                  width: double.infinity,
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    fit: pw.BoxFit.cover,
                  ),
                ),

              pw.SizedBox(height: 20),

              /// PROPERTY DETAILS
              pw.Text(
                "Property Details",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              pw.SizedBox(height: 8),

              pw.Text("Property: $propertyName"),
              pw.Text("Location: $location"),
              pw.Text("Check-in: $checkIn"),
              pw.Text("Check-out: $checkOut"),

              pw.SizedBox(height: 20),

              /// GUEST DETAILS
              pw.Text(
                "Guest Details",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              pw.SizedBox(height: 8),

              pw.Text("Name: $guestName"),
              pw.Text("Phone: $guestPhone"),
              pw.Text("Email: $userEmail"),

              pw.SizedBox(height: 20),

              pw.Divider(),

              /// PRICE
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Total Paid",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "₹${totalPrice.toStringAsFixed(0)}",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              pw.Text(
                "Thank you for booking with Skybase!",
                style: const pw.TextStyle(fontSize: 12),
              ),

            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}

/// Simple screen wrapper that allows generating and printing an invoice for a
/// booking. This replaces the previously-missing `InvoiceScreen` widget used
/// by booking flows.
class InvoiceScreen extends StatefulWidget {
  final CarBooking booking;
  final VoidCallback? onConfirmPay;

  const InvoiceScreen({super.key, required this.booking, this.onConfirmPay});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      await InvoiceService.generateInvoice(
        bookingId: widget.booking.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        propertyName: widget.booking.carName,
        location: '',
        checkIn: widget.booking.startDate.toIso8601String(),
        checkOut: widget.booking.endDate.toIso8601String(),
        totalPrice: widget.booking.finalTotal.toDouble(),
        userEmail: userEmail,
        guestName: '',
        guestPhone: '',
        propertyImage: null,
      );
    } catch (e) {
      debugPrint('Invoice generation failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate invoice: $e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking: ${widget.booking.carName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('From: ${widget.booking.startDate.toLocal()}'),
            Text('To: ${widget.booking.endDate.toLocal()}'),
            const SizedBox(height: 16),
            Text('Total: ₹${widget.booking.finalTotal}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generate,
                    child: _isGenerating ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Generate & Print Invoice'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.onConfirmPay != null) widget.onConfirmPay!();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Confirm Booking'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}