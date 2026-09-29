import 'package:get/get.dart';

import '../../../data/models/product.dart';

class FavoritesController extends GetxController {
  final RxMap<int, Product> _favorites = <int, Product>{}.obs;

  List<Product> get favoriteProducts =>
      List<Product>.unmodifiable(_favorites.values);

  bool isFavorite(int productId) => _favorites.containsKey(productId);

  void addFavorite(Product product) {
    _favorites[product.id] = product;
  }

  void removeFavorite(int productId) {
    _favorites.remove(productId);
  }

  void toggleFavorite(Product product) {
    if (isFavorite(product.id)) {
      removeFavorite(product.id);
    } else {
      addFavorite(product);
    }
  }
}
