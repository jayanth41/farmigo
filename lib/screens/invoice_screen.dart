import 'package:flutter/material.dart';
import '../models/car_booking.dart';

class InvoiceScreen extends StatefulWidget {
  final CarBooking booking;
  final VoidCallback onConfirmPay;

  const InvoiceScreen({
    super.key,
    required this.booking,
    required this.onConfirmPay,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final bgColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Booking Invoice',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Invoice Header Card
            _buildInvoiceHeader(booking, textColor),
            const SizedBox(height: 24),

            // Booking Details
            _buildSectionTitle('Booking Details', textColor),
            _buildDetailCard(
              children: [
                _buildDetailRow('Car', booking.carName, textColor),
                const Divider(height: 16, thickness: 0.5),
                _buildDetailRow(
                  'Check-in',
                  _formatDateTime(booking.startDate),
                  textColor,
                ),
                const Divider(height: 16, thickness: 0.5),
                _buildDetailRow(
                  'Check-out',
                  _formatDateTime(booking.endDate),
                  textColor,
                ),
                if (booking.isSameDayBooking) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _buildDetailRow(
                    'Duration',
                    '${booking.hours} hours',
                    textColor,
                  ),
                ] else ...[
                  const Divider(height: 16, thickness: 0.5),
                  _buildDetailRow(
                    'Duration',
                    '${booking.numberOfDays} days',
                    textColor,
                  ),
                ],
                if (booking.driverRequested) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _buildDetailRow(
                    'Driver',
                    'Requested ✓',
                    textColor,
                    valueColor: Colors.green,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Price Breakdown
            _buildSectionTitle('Price Breakdown', textColor),
            _buildDetailCard(
              children: [
                if (booking.hourlyTotal > 0) ...[
                  _buildPriceRow(
                    'Hourly Rate',
                    '₹${booking.hourlyTotal}',
                    textColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                ] else ...[
                  if (booking.weekdayTotal > 0) ...[
                    _buildPriceRow(
                      'Weekday (${_countWeekdays(booking.startDate, booking.endDate)} days)',
                      '₹${booking.weekdayTotal}',
                      textColor,
                    ),
                    const Divider(height: 16, thickness: 0.5),
                  ],
                  if (booking.weekendTotal > 0) ...[
                    _buildPriceRow(
                      'Weekend (${_countWeekends(booking.startDate, booking.endDate)} days)',
                      '₹${booking.weekendTotal}',
                      textColor,
                    ),
                    const Divider(height: 16, thickness: 0.5),
                  ],
                ],
                if (booking.driverTotal > 0) ...[
                  _buildPriceRow(
                    'Driver Charges',
                    '₹${booking.driverTotal}',
                    textColor,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                ],
                _buildPriceRow(
                  'Subtotal',
                  '₹${booking.finalTotal - (booking.driverTotal > 0 ? booking.driverTotal : 0)}',
                  textColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Final Total
            _buildFinalTotalCard(booking, textColor),
            const SizedBox(height: 32),

            // Confirm & Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleConfirmAndPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm & Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(CarBooking booking, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Summary',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            booking.carName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Period',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${booking.finalTotal}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String amount, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalTotalCard(CarBooking booking, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Final Total',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '₹${booking.finalTotal}',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleConfirmAndPay() async {
    setState(() => _isProcessing = true);

    try {
      // In a real app, you would integrate Razorpay here
      // For now, we'll just call the callback
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      widget.onConfirmPay();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed! Payment processed.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatDateTime(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _countWeekdays(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  int _countWeekends(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday == DateTime.saturday || current.weekday == DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }
}
