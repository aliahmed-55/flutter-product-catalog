abstract final class ApiEndpoints {
  static const baseUrl = 'https://dummyjson.com';
  static const products = '/products';
  static const search = '$products/search';
  static const categories = '$products/categories';

  static String product(int id) => '$products/$id';

  static String productsByCategory(String slug) =>
      '$products/category/${Uri.encodeComponent(slug)}';
}
