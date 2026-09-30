import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';

import 'support/fake_product_repository.dart';

void main() {
  test('Favorites are keyed by ID and removing one preserves the others', () {
    final controller = FavoritesController();
    final products = productPage(3).products;
    for (final product in products) {
      controller.addFavorite(product);
    }
    controller.addFavorite(products.first);
    expect(controller.favoriteProducts.map((product) => product.id), [1, 2, 3]);
    controller.removeFavorite(2);
    controller.removeFavorite(2);
    expect(controller.isFavorite(2), isFalse);
    expect(controller.favoriteProducts.map((product) => product.id), [1, 3]);
    controller.toggleFavorite(products.first);
    expect(controller.isFavorite(1), isFalse);
    controller.toggleFavorite(products.first);
    expect(controller.isFavorite(1), isTrue);
    expect(controller.favoriteProducts.length, 2);
  });
}
