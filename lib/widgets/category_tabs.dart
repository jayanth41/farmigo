import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

typedef CategoryChanged = void Function(String category);

class CategoryTabs extends StatelessWidget {
  final String activeCategory;
  final CategoryChanged onCategoryChange;
  final List<String> categories;

  const CategoryTabs({
    super.key,
    required this.activeCategory,
    required this.onCategoryChange,
    this.categories = const ['Farmhouses', 'Villas', 'Hotels', 'Car rentals', 'Flight', 'Hourly rentals'],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((c) {
            final selected = c == activeCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => onCategoryChange(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // leading icon per category
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          _iconForCategory(c),
                          size: 16,
                          color: selected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      Text(
                        c,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _iconForCategory(String c) {
    final key = c.toLowerCase();
    if (key.contains('farm')) return Icons.agriculture;
    if (key.contains('villa')) return Icons.villa;
    if (key.contains('hotel')) return Icons.hotel;
    if (key.contains('car')) return Icons.directions_car;
    if (key.contains('flight')) return Icons.flight;
    if (key.contains('hour')) return Icons.access_time;
    return Icons.place;
  }
}
