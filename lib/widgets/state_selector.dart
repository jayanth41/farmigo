import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StateSelector extends StatelessWidget {
  final String selectedState;
  final Function(String) onSelect;

  const StateSelector({
    super.key,
    required this.selectedState,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openStateSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // removed heavy grey shadow to match requested flat look
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              selectedState,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  void _openStateSheet(BuildContext context) {
    final states = [
      "Telangana",
      "Andhra Pradesh",
      "Karnataka",
      "Maharashtra",
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        children: states
            .map(
              (state) => ListTile(
                title: Text(state),
                trailing: state == selectedState
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(state);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
