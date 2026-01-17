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
            children: const [
              Icon(Icons.near_me_outlined, size: 18, color: AppColors.iconGrey),
              SizedBox(width: 6),
              Text(
                "Your Location",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          // RIGHT: Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
              color: AppColors.white,
            ),
            child: Row(
              children: const [
                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  "All India",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
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
