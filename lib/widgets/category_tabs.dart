import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

typedef CategoryChanged = void Function(String category);

/// Horizontal category tabs used on Home screen.
class CategoryTabs extends StatelessWidget {
  final String activeCategory;
  final CategoryChanged onCategoryChange;
  final List<String> categories;

  const CategoryTabs({
    super.key,
    required this.activeCategory,
    required this.onCategoryChange,
    this.categories = const [
      'Farmhouses',
      'Villas',
      'Hotels',
      'Car rentals',
      'Flight',
      'Hourly rentals'
    ],
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
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // leading icon per category
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          _iconForCategory(c),
                          color: selected ? Colors.white : AppColors.primary,
                          size: 18,
                        ),
                      ),
                      Text(
                        c,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textMain,
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
    return Icons.home;
  }
}

/// Square category grid used on some screens — kept here for convenience.
class CategoryGrid extends StatelessWidget {
  final void Function(String category)? onTap;

  const CategoryGrid({super.key, this.onTap});

  static const List<Color> _palette = [
    AppColors.primaryDark,
    AppColors.greenDark,
    AppColors.tealDark,
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'label': 'Farmhouses', 'icon': Icons.agriculture},
      {'label': 'Villas', 'icon': Icons.villa},
      {'label': 'Hotels', 'icon': Icons.hotel},
      {'label': 'Flights', 'icon': Icons.flight},
      {'label': 'Car Rentals', 'icon': Icons.directions_car},
      {'label': 'Halls', 'icon': Icons.apartment},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          final bg = _palette[i % _palette.length];
          return InkWell(
            onTap: () => onTap?.call(item['label'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(item['icon'] as IconData, size: 30, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
