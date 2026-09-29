import '../models/category.dart';
import '../models/product.dart';
import '../models/product_page.dart';
import '../services/product_api_service.dart';
import 'product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._service);

  final ProductApiService _service;

  @override
  Future<ProductPage> getProducts({required int limit, required int skip}) {
    return _service.getProducts(limit: limit, skip: skip);
  }

  @override
  Future<ProductPage> searchProducts({
    required String query,
    required int limit,
    required int skip,
  }) {
    return _service.searchProducts(query: query, limit: limit, skip: skip);
  }

  @override
  Future<ProductPage> getProductsByCategory({
    required String slug,
    required int limit,
    required int skip,
  }) {
    return _service.getProductsByCategory(slug: slug, limit: limit, skip: skip);
  }

  @override
  Future<Product> getProduct(int id) => _service.getProduct(id);

  @override
  Future<List<Category>> getCategories() => _service.getCategories();
}
