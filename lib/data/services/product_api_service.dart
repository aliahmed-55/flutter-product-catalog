import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_page.dart';

class ProductApiService {
  const ProductApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<ProductPage> getProducts({required int limit, required int skip}) {
    return _getProductPage(ApiEndpoints.products, limit: limit, skip: skip);
  }

  Future<ProductPage> searchProducts({
    required String query,
    required int limit,
    required int skip,
  }) {
    return _getProductPage(
      ApiEndpoints.search,
      limit: limit,
      skip: skip,
      query: query,
    );
  }

  Future<ProductPage> getProductsByCategory({
    required String slug,
    required int limit,
    required int skip,
  }) {
    return _getProductPage(
      ApiEndpoints.productsByCategory(slug),
      limit: limit,
      skip: skip,
    );
  }

  Future<Product> getProduct(int id) async {
    final data = await _apiClient.get(ApiEndpoints.product(id));
    try {
      return Product.fromJson(data as Map<String, dynamic>);
    } on TypeError {
      throw const ApiException(
        'The product data could not be read. Please try again.',
      );
    }
  }

  Future<List<Category>> getCategories() async {
    final data = await _apiClient.get(ApiEndpoints.categories);
    try {
      return List<Category>.unmodifiable(
        (data as List<dynamic>).map(
          (category) => Category.fromJson(category as Map<String, dynamic>),
        ),
      );
    } on TypeError {
      throw const ApiException(
        'The category data could not be read. Please try again.',
      );
    }
  }

  Future<ProductPage> _getProductPage(
    String path, {
    required int limit,
    required int skip,
    String? query,
  }) async {
    final data = await _apiClient.get(
      path,
      queryParameters: {
        'limit': limit.toString(),
        'skip': skip.toString(),
        'q': ?query,
      },
    );
    try {
      return ProductPage.fromJson(data as Map<String, dynamic>);
    } on TypeError {
      throw const ApiException(
        'The product list could not be read. Please try again.',
      );
    }
  }
}
