import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/data/models/category.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/data/models/product_page.dart';
import 'package:product_catalog/data/repositories/product_repository.dart';

const beauty = Category(
  slug: 'beauty',
  name: 'Beauty',
  url: 'https://example.test/beauty',
);
const groceries = Category(
  slug: 'groceries',
  name: 'Groceries',
  url: 'https://example.test/groceries',
);

ProductPage productPage(int count, {int skip = 0, int? total, List<int>? ids}) {
  return ProductPage(
    products: List.generate(count, (index) {
      final id = ids?[index] ?? skip + index + 1;
      return Product(
        id: id,
        title: 'Product $id',
        description: 'Test product',
        price: 9.99,
        discountPercentage: 10,
        rating: 4.5,
        stock: 20,
        category: 'beauty',
        thumbnail: '',
        images: const [],
      );
    }),
    total: total ?? count,
    skip: skip,
    limit: 10,
  );
}

class FakeProductRepository implements ProductRepository {
  FakeProductRepository(this.response);

  Future<ProductPage> Function() response;
  Future<ProductPage> Function(String source, int skip)? onPage;
  Future<List<Category>> Function()? categoryResponse;
  final requests = <({String source, int skip})>[];
  int categoryCalls = 0;
  int get calls => requests.length;

  Future<ProductPage> _page(String source, int limit, int skip) {
    expect(limit, 10);
    requests.add((source: source, skip: skip));
    return onPage?.call(source, skip) ?? response();
  }

  @override
  Future<ProductPage> getProducts({required int limit, required int skip}) =>
      _page('all', limit, skip);

  @override
  Future<ProductPage> searchProducts({
    required String query,
    required int limit,
    required int skip,
  }) => _page('search:$query', limit, skip);

  @override
  Future<ProductPage> getProductsByCategory({
    required String slug,
    required int limit,
    required int skip,
  }) => _page('category:$slug', limit, skip);

  @override
  Future<Product> getProduct(int id) => throw UnimplementedError();

  @override
  Future<List<Category>> getCategories() {
    categoryCalls++;
    return categoryResponse?.call() ?? Future.value([beauty, groceries]);
  }
}
