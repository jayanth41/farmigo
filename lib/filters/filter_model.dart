import '../models/category.dart';

class FilterModel {
  final Category category;
  final Map<String, dynamic> values;

  FilterModel({required this.category, Map<String, dynamic>? values}) : values = values ?? {};

  Map<String, dynamic> toMap() => {'category': category.toString(), 'values': values};

  static FilterModel fromMap(Map<String, dynamic> map) {
    final catStr = map['category'] as String? ?? 'Category.all';
    final cat = Category.values.firstWhere((c) => c.toString() == catStr, orElse: () => Category.all);
    return FilterModel(category: cat, values: Map<String, dynamic>.from(map['values'] ?? {}));
  }
}
