import 'package:flutter/foundation.dart' show ChangeNotifier;
import '../models/category.dart';
import 'filter_model.dart';

class FiltersProvider extends ChangeNotifier {
  final Map<Category, FilterModel> _filters = {};

  FilterModel getFilter(Category category) {
    return _filters[category] ??= FilterModel(category: category);
  }

  void setFilter(Category category, Map<String, dynamic> values) {
    _filters[category] = FilterModel(category: category, values: Map<String, dynamic>.from(values));
    notifyListeners();
  }

  void resetFilter(Category category) {
    _filters[category] = FilterModel(category: category);
    notifyListeners();
  }

  Map<String, dynamic>? getRaw(Category category) => _filters[category]?.values;
}
