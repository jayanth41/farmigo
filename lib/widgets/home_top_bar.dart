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
          // Left group: menu, breadcrumb, logo and 'Skybase' text
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Open the scaffold drawer when the menu is tapped
                  Scaffold.of(context).openDrawer();
                },
                child: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              // breadcrumb (compact) - icon only; text removed for a cleaner header
              const SizedBox(width: 6),
              // logo beside breadcrumb
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.park, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              // SKYBASE rich mark (SKY + BASE) with slight letter spacing
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'SKY',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2),
                    ),
                    TextSpan(
                      text: 'BASE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary.withOpacity(0.8), letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),

              // Right-side actions: filter and profile (profile visible in green)
            ],
          ),

          const Spacer(),

          // make menu open the drawer; keep spacing on the right
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
