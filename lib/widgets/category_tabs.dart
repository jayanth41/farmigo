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
    // Colors are taken directly from AppColors.primary for the filled style.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((c) {
            final isActive = c == activeCategory;
            final primary = Theme.of(context).colorScheme.primary;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: isActive ? Colors.white : primary,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onCategoryChange(c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : primary,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isActive ? primary : Colors.transparent,
                        width: isActive ? 1.5 : 0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isActive ? primary.withOpacity(0.06) : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForCategory(c),
                              color: isActive ? primary : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        Text(
                          c,
                          style: TextStyle(
                            color: isActive ? primary : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

  /// Optional custom card builder for compatibility with callers that pass
  /// a `cardBuilder` parameter (older HomeScreen code).
  /// Signature: (context, label, iconData, selectedCategory, onTap)
  final Widget Function(BuildContext, String, IconData, String, void Function(String))? cardBuilder;

  const CategoryGrid({
    super.key,
    this.onTap,
    this.selectedCategory = 'All',
    this.cardBuilder,
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
  // background and text colors are derived from theme where needed

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

          // If caller provided a custom builder (older HomeScreen expects
          // `cardBuilder:`), use it for rendering the tile.
          if (widget.cardBuilder != null) {
            return widget.cardBuilder!(context, label, icon, _localSelectedCategory, (lbl) {
              setState(() {
                _localSelectedCategory = lbl;
              });
              widget.onTap?.call(lbl);
            });
          }

          return InkWell(
            onTap: () {
              setState(() {
                _localSelectedCategory = label;
              });
              widget.onTap?.call(label);
            },
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? const Color.fromARGB(255, 41, 70, 92) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color.fromARGB(255, 41, 70, 92),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                      color: isSelected ? Colors.white24 : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : const Color.fromARGB(255, 41, 70, 92),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : const Color.fromARGB(255, 41, 70, 92),
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
