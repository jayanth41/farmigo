import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LocationBar extends StatelessWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT: Your Location text
          Row(
            children: [
              Icon(Icons.near_me_outlined, size: 18, color: AppColors.iconGrey),
              const SizedBox(width: 6),
              Text(
                "Your Location",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),

          // RIGHT: Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border(context)),
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children:  [
                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  "All India",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: AppColors.iconGrey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
