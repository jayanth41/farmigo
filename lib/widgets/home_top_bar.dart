import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // MENU
          Icon(Icons.menu, color: AppColors.textMain),

          // LOGO
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.park, color: Colors.white),
          ),

          Row(
            children: [
              // FILTER
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune, color: AppColors.primary),
              ),
              const SizedBox(width: 12),

              // PROFILE
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
