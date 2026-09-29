abstract final class AppRoutes {
  static const home = '/';
  static const favorites = '/favorites';
  static const productDetails = '/products/:id';

  static String product(int id) => '/products/$id';
}
