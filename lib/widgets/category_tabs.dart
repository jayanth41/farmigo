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
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : bgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          _iconForCategory(c),
                          color: selected
                              ? Colors.white
                              : AppColors.primary,
                          size: 18,
                        ),
                      ),
                      Text(
                        c,
                        style: TextStyle(
                          color: selected ? Colors.white : textColor,
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

/// Square category grid used on Home screen with selection state
class CategoryGrid extends StatefulWidget {
  final void Function(String category)? onTap;
  final String selectedCategory;

  const CategoryGrid({
    super.key,
    this.onTap,
    this.selectedCategory = 'All',
  });

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  late String _localSelectedCategory;

  @override
  void initState() {
    super.initState();
    _localSelectedCategory = widget.selectedCategory;
  }

  @override
  void didUpdateWidget(CategoryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _localSelectedCategory = widget.selectedCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final List<Map<String, dynamic>> items = [
      {'label': 'Farmhouses', 'icon': Icons.agriculture},
      {'label': 'Villas', 'icon': Icons.villa},
      {'label': 'Hotels', 'icon': Icons.hotel},
      {'label': 'Flights', 'icon': Icons.flight},
      {'label': 'Car Rentals', 'icon': Icons.directions_car},
      {'label': 'Hourly Rentals', 'icon': Icons.access_time},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = label == _localSelectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _localSelectedCategory = label;
              });
              widget.onTap?.call(label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.white : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? Colors.white : textColor,
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
