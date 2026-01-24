import 'package:flutter/material.dart';
import '../widgets/image_with_fallback.dart';
import '../theme/app_theme.dart';

class BookingItem extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingItem({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.bookingCardColor,
        borderRadius: BorderRadius.circular(AppTheme.bookingCardRadius),
        boxShadow: [
          BoxShadow(color: AppTheme.bookingCardShadowColor, blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.bookingCardRadius),
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return isWide
              ? Row(
                  children: [
                    // Image
                    Container(
                      width: AppTheme.bookingImageWidth,
                      height: AppTheme.bookingImageHeight,
                      color: Colors.grey[200],
                      child: ImageWithFallback(
                        imageUrl: booking['image'] ?? '',
                        height: AppTheme.bookingImageHeight,
                        width: AppTheme.bookingImageWidth,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildContent(context),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: ImageWithFallback(
                        imageUrl: booking['image'] ?? '',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildContent(context),
                    ),
                  ],
                );
        }),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['name'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          booking['location'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _statusBadge(status),
          ],
        ),
        const SizedBox(height: 12),

        // Details grid
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _detailColumn('Check-in', booking['checkIn']),
            _detailColumn('Check-out', booking['checkOut']),
            _detailColumn('Guests', booking['guests']),
            _detailColumn('Total Amount', '₹${booking['totalAmount'] ?? 0}'),
          ],
        ),
        const SizedBox(height: 8),
  Text('Booking ID: ${booking['bookingId'] ?? ''}', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _actionButtons(context, status),
        ),
      ],
    );
  }

  Widget _detailColumn(String title, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value ?? '-', style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    switch (status) {
      case 'confirmed':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.bookingBadgeConfirmedBg, borderRadius: BorderRadius.circular(20)),
          child: Row(children: const [Icon(Icons.check_circle, color: AppTheme.bookingBadgeConfirmedFg, size: 16), SizedBox(width: 6), Text('Confirmed', style: TextStyle(color: AppTheme.bookingBadgeConfirmedFg))]),
        );
      case 'upcoming':
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.bookingBadgeUpcomingBg, borderRadius: BorderRadius.circular(20)),
            child: Row(children: const [Icon(Icons.access_time, color: AppTheme.bookingBadgeUpcomingFg, size: 16), SizedBox(width: 6), Text('Upcoming', style: TextStyle(color: AppTheme.bookingBadgeUpcomingFg))]),
          );
      case 'completed':
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
            child: const Text('Completed', style: TextStyle(color: Colors.grey)),
          );
      case 'cancelled':
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.bookingBadgeCancelledBg, borderRadius: BorderRadius.circular(20)),
            child: Row(children: const [Icon(Icons.close, color: AppTheme.bookingBadgeCancelledFg, size: 16), SizedBox(width: 6), Text('Cancelled', style: TextStyle(color: AppTheme.bookingBadgeCancelledFg))]),
          );
      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _actionButtons(BuildContext context, String status) {
    final List<Widget> actions = [];
    actions.add(_outlineButton(context, 'View Details', onPressed: () {}));
    if (status != 'completed' && status != 'cancelled') {
      actions.add(_outlineButton(context, 'Cancel Booking', onPressed: () {}, textColor: AppTheme.bookingBadgeCancelledFg, borderColor: AppTheme.bookingDangerBorder));
      actions.add(_outlineButton(context, 'Modify Booking', onPressed: () {}));
    }
    actions.add(_outlineButton(context, 'Invoice', onPressed: () {}, leading: const Icon(Icons.download, size: 16)));
    return actions;
  }

  Widget _outlineButton(BuildContext context, String label, {VoidCallback? onPressed, Icon? leading, Color? textColor, Color? borderColor}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: leading ?? const SizedBox.shrink(),
      label: Text(label, style: TextStyle(color: textColor ?? Colors.black87)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor ?? AppTheme.bookingActionBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.bookingButtonRadius)),
      ),
    );
  }
}