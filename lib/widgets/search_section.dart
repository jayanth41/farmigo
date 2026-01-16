import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'premium_search_bar.dart';

typedef SearchChanged = void Function(String query);

class SearchSection extends StatelessWidget {
  final String category;
  final TextEditingController controller;
  final SearchChanged onChanged;

  const SearchSection({
    super.key,
    required this.category,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumSearchBar(
            controller: controller,
            onChanged: onChanged,
            hintText: 'Search $category or location...',
            variant: SearchBarVariant.standard,
          ),
          const SizedBox(height: 10),
          // small quick-search chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(label: Text('Near me')),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(label: Text('Pet friendly')),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(label: Text('Pool')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
