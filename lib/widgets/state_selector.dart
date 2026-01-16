import 'package:flutter/material.dart';

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
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Color(0xFF1B5E20)),
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
