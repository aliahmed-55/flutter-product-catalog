import '../models/category.dart';
import '../models/product.dart';
import '../models/product_page.dart';

abstract class ProductRepository {
  Future<ProductPage> getProducts({required int limit, required int skip});

  Future<ProductPage> searchProducts({
    required String query,
    required int limit,
    required int skip,
  });

  Future<ProductPage> getProductsByCategory({
    required String slug,
    required int limit,
    required int skip,
  });

  Future<Product> getProduct(int id);

  Future<List<Category>> getCategories();
}
