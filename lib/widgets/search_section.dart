import 'package:flutter/material.dart';


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
          // Simplified search input (PremiumSearchBar removed)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: InputDecoration.collapsed(hintText: 'Search $category or location...'),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
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
