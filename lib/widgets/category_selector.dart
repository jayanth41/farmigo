import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onSelect;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      {"label": "Farmhouses", "icon": Icons.agriculture},
      {"label": "Villas", "icon": Icons.villa},
      {"label": "Hotels", "icon": Icons.hotel},
      {"label": "Halls", "icon": Icons.account_balance},
    ];

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat["label"];
          return GestureDetector(
            onTap: () => onSelect(cat["label"] as String),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.12),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat["icon"] as IconData,
                    size: 28,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat["label"] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
