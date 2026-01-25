import 'package:get/get.dart';

class FavoritesController extends GetxController {
  var favorites = <String>[].obs;

  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
  }

  bool isFavorite(String id) {
    return favorites.contains(id);
  }
}
